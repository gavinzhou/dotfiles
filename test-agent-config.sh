#!/bin/bash
# Tests dot_claude/modify_settings.json.tmpl and dot_codex/modify_private_config.toml.tmpl
# with a fake `op`. Run from the repo root: bash test-agent-config.sh
set -euo pipefail

src=$PWD
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

work=$(mktemp -d)
(
  trap 'rm -rf "$work"' EXIT
  claude=$(chezmoi --source "$src" execute-template < dot_claude/modify_settings.json.tmpl)
  codex=$(chezmoi --source "$src" execute-template < dot_codex/modify_private_config.toml.tmpl)

  # Fake op: prints test-<field> when OP_OK=1, else fails like a locked vault.
  mkdir "$work/bin"
  cat > "$work/bin/op" <<'EOF'
#!/bin/bash
[[ -z ${OP_LOG:-} ]] || echo "$*" >> "$OP_LOG"
[[ ${OP_OK:-0} == 1 ]] || exit 1
echo "test-${2##*/}"
EOF
  chmod +x "$work/bin/op"
  export PATH="$work/bin:$PATH"

  # run <script> <input file>: callers redirect stdout to a file, so trailing
  # newlines survive; a failing script fails the run (set -e) unless checked.
  run() { /bin/bash -c "$1" < "$2"; }

  # Claude: a new Mac gets the baseline.
  : > "$work/empty"
  run "$claude" "$work/empty" > "$work/c1"
  check "claude: empty file becomes the baseline" \
    '[[ $(jq -S . "$work/c1") == "$(jq -S . claude-settings.json)" ]]'

  # Claude: local-only keys and allow entries pass through untouched.
  jq '. + {autoMode: {soft_deny: ["x"]}} | .permissions.allow += ["Bash(ls:*)"]' \
    claude-settings.json > "$work/c2"
  run "$claude" "$work/c2" > "$work/c2.out"
  check "claude: unchanged file passes through byte for byte" 'cmp -s "$work/c2" "$work/c2.out"'

  # Claude: a changed shared key is put back; local keys and allow order stay.
  jq '.tui = "default" | .autoMode = {a: 1} | .permissions.allow = ["Bash(ls:*)"]' \
    claude-settings.json > "$work/c3"
  run "$claude" "$work/c3" > "$work/c3.out"
  check "claude: shared key restored" '[[ $(jq -r .tui "$work/c3.out") == fullscreen ]]'
  check "claude: autoMode kept" '[[ $(jq -c .autoMode "$work/c3.out") == "{\"a\":1}" ]]'
  check "claude: allow keeps local first, adds shared" \
    '[[ $(jq -c .permissions.allow "$work/c3.out") == "[\"Bash(ls:*)\",\"Read(~/Code/**)\"]" ]]'

  # Codex: a new Mac with 1Password unlocked gets every MCP secret.
  OP_OK=1 run "$codex" "$work/empty" > "$work/x1"
  yq -p toml -o json . "$work/x1" > "$work/x1.json"
  check "codex: slack token filled" \
    '[[ $(jq -r ".mcp_servers[\"slack-official\"].http_headers.Authorization" "$work/x1.json") == "Bearer test-SLACK_MCP_TOKEN" ]]'
  check "codex: stitch key filled" \
    '[[ $(jq -r ".mcp_servers.stitch.http_headers[\"X-Goog-Api-Key\"]" "$work/x1.json") == test-STITCH_API_KEY ]]'
  check "codex: penpot url filled" \
    '[[ $(jq -r .mcp_servers.penpot.url "$work/x1.json") == "https://design.penpot.app/mcp/stream?userToken=test-PENPOT_MCP_TOKEN" ]]'
  check "codex: shared model set" '[[ $(jq -r .model "$work/x1.json") == "$(yq -p toml -oy .model codex-config.toml)" ]]'

  # Codex: unchanged file (secrets, app-written keys) passes through, op unused.
  { cat "$work/x1"; printf '\n[projects."/tmp/x"]\ntrust_level = "trusted"\n'; } > "$work/x2"
  run "$codex" "$work/x2" > "$work/x2.out"
  check "codex: unchanged file passes through byte for byte" 'cmp -s "$work/x2" "$work/x2.out"'

  # Codex: without 1Password, servers missing a secret are left out, not half set.
  run "$codex" "$work/empty" > "$work/x3" 2> "$work/x3.err"
  yq -p toml -o json . "$work/x3" > "$work/x3.json"
  check "codex: no secret, no server" \
    '[[ $(jq -c "[.mcp_servers | keys[]?]" "$work/x3.json") == "[]" ]]'
  check "codex: says what it left out" '[[ $(grep -c "left out" "$work/x3.err") == 3 ]]'
  check "codex: no secret text in output" '! grep -q "test-" "$work/x3"'

  # Codex: an existing file missing a server's secret (removed on purpose) never
  # asks 1Password, so a daily sync can't prompt for Touch ID.
  jq 'del(.mcp_servers.penpot)' "$work/x1.json" | yq -p json -o toml . > "$work/x4"
  OP_OK=1 OP_LOG="$work/op.log" run "$codex" "$work/x4" > "$work/x4.out"
  check "codex: existing file never calls op" '[[ ! -e $work/op.log ]]'
  check "codex: removed server stays removed" 'cmp -s "$work/x4" "$work/x4.out"'

  # Codex: a secret that is only its prefix is not a secret; the server goes,
  # still without asking 1Password.
  jq '.mcp_servers["slack-official"].http_headers.Authorization = "Bearer "' "$work/x1.json" |
    yq -p json -o toml . > "$work/x5"
  OP_OK=1 OP_LOG="$work/op.log" run "$codex" "$work/x5" | yq -p toml -o json . > "$work/x5.json"
  check "codex: empty token drops the server" '[[ $(jq ".mcp_servers | has(\"slack-official\")" "$work/x5.json") == false ]]'
  check "codex: empty token never calls op" '[[ ! -e $work/op.log ]]'

  # Codex: a config that is only comments is treated as empty, not an error.
  printf '# nothing yet\n' > "$work/x6"
  check "codex: comment-only file works" 'run "$codex" "$work/x6" 2>/dev/null | yq -p toml -e .model >/dev/null'

  # Claude: a settings file holding two JSON documents stops the apply.
  printf '{}\n{}\n' > "$work/c4"
  check "claude: two JSON documents fail" '! run "$claude" "$work/c4" >/dev/null 2>&1'

  # Failures reach the test: a script that exits non-zero is not a pass.
  check "run passes exit codes through" '! run "exit 23" "$work/empty"'

  exit "$fail"
) || fail=1

# The temp directory must be gone afterwards.
check "temp directory removed" '[[ ! -e $work ]]'
exit "$fail"
