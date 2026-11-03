#!/bin/bash
# Tests wt in throwaway repos. Run from the repo root: bash test-wt.sh
# (CI also runs it with macOS /bin/bash 3.2.)
# Variables are read inside eval strings; "done" is a wt subcommand.
# shellcheck disable=SC2034,SC1010
set -uo pipefail

src=$PWD
fail=0
check() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }

work=$(mktemp -d)
(
  pids=()
  cleanup() { kill ${pids[@]+"${pids[@]}"} 2>/dev/null; wait 2>/dev/null; rm -rf "$work"; }
  trap cleanup EXIT
  export WT_CODE_DIR="$work/Code" WT_GRACE_SECONDS=3600
  export GIT_CONFIG_GLOBAL="$work/gitconfig" GIT_CONFIG_NOSYSTEM=1
  git config --global user.name t; git config --global user.email t@t
  git config --global init.defaultBranch main
  wt() { "$src/wt" "$@"; }

  # An owner process we can kill to make the owner "gone".
  owner() { sleep 600 >/dev/null 2>&1 & pids+=($!); OWNER=$!; }
  gone() { kill "$1"; wait "$1" 2>/dev/null; }

  git init -q --bare "$work/origin.git"
  repo="$work/Code/g/repo"
  git init -q "$repo"
  cd "$repo" || exit 1
  repo=$(pwd -P)
  git commit -q --allow-empty -m init
  git remote add origin "$work/origin.git"
  git push -q -u origin main
  git remote set-head origin main
  wtdir="$repo/.claude/worktrees"
  locked() { git worktree list --porcelain | grep -A3 "^worktree $1\$" | sed -n 's/^locked //p'; }

  # --- new ---
  owner; o1=$OWNER
  out=$(WT_OWNER_PID=$o1 wt new a --task "repo#1" 2>/dev/null)
  check "new: prints the path last" '[[ $out == "$wtdir/a" && -d $wtdir/a ]]'
  check "new: branch worktree-a" '[[ $(git -C "$wtdir/a" branch --show-current) == worktree-a ]]'
  check "new: lock names owner pid and start" \
    '[[ $(locked "$wtdir/a") == "wt shell a task=repo#1 (pid $o1 start "*")" ]]'
  check "new: main checkout stays clean" '[[ -z $(git status --porcelain) ]]'
  check "new: list shows owner alive" '[[ $(wt list) == *"$wtdir/a"*clean*"在：wt shell a"* ]]'
  check "new: bad name refused" '! wt new ../x 2>/dev/null'
  check "new: existing name refused" '! WT_OWNER_PID=$o1 wt new a 2>/dev/null'

  # --- done ---
  check "done: other live owner is refused" '! WT_OWNER_PID=$$ wt done a 2>/dev/null && [[ -d $wtdir/a ]]'
  echo x > "$wtdir/a/f"
  WT_OWNER_PID=$o1 wt done a >/dev/null 2>&1; rc=$?
  check "done: uncommitted change refused with exit 2" '[[ $rc == 2 && -f $wtdir/a/f ]]'
  git -C "$wtdir/a" add f; git -C "$wtdir/a" commit -q -m f
  sha=$(git -C "$wtdir/a" rev-parse HEAD)
  git remote set-url origin "$work/missing.git"
  WT_OWNER_PID=$o1 wt done a >/dev/null 2>&1; rc=$?
  check "done: push fails, worktree and branch kept" '[[ $rc != 0 && -d $wtdir/a ]] && git show-ref -q --verify refs/heads/worktree-a'
  git remote set-url origin "$work/origin.git"
  WT_OWNER_PID=$o1 wt done a >/dev/null 2>&1
  check "done: the exact commit is on origin" \
    '[[ $(git --git-dir="$work/origin.git" rev-parse refs/heads/worktree-a 2>/dev/null) == "$sha" ]]'
  check "done: worktree removed" '[[ ! -e $wtdir/a && $(git worktree list | wc -l) -eq 1 ]]'
  check "done: local branch removed once it is on origin" '! git show-ref -q --verify refs/heads/worktree-a'
  check "done: empty .claude removed" '[[ ! -e $repo/.claude ]]'

  WT_OWNER_PID=$o1 wt new b >/dev/null 2>&1
  echo x > "$wtdir/b/f"
  WT_OWNER_PID=$o1 wt done b --discard >/dev/null 2>&1
  check "done --discard: removes a dirty worktree" '[[ ! -e $wtdir/b ]]'

  WT_OWNER_PID=$o1 wt new e >/dev/null 2>&1
  echo secret > "$wtdir/e/.env"; echo .env > "$wtdir/e/.gitignore"; git -C "$wtdir/e" add .gitignore; git -C "$wtdir/e" commit -q -m ignore
  git -C "$wtdir/e" push -q origin HEAD:refs/heads/worktree-e
  WT_OWNER_PID=$o1 wt done e >/dev/null 2>&1; rc=$?
  check "done: ignored file (.env) refused with exit 2" '[[ $rc == 2 && -f $wtdir/e/.env ]]'
  WT_OWNER_PID=$o1 wt done e --discard >/dev/null 2>&1
  check "done --discard: removes it" '[[ ! -e $wtdir/e ]]'

  WT_OWNER_PID=$o1 wt new c >/dev/null 2>&1
  (cd "$wtdir/c" && WT_OWNER_PID=$o1 "$src/wt" done >/dev/null 2>&1)
  check "done: no argument means the current worktree" '[[ ! -e $wtdir/c ]]'

  # --- sweep ---
  owner; oa=$OWNER; owner; od=$OWNER; owner; ox=$OWNER
  WT_OWNER_PID=$oa wt new alive >/dev/null 2>&1
  WT_OWNER_PID=$oa wt new alivecn --task "修复 #1" >/dev/null 2>&1
  touch -t 202601010000 "$wtdir/alivecn"
  WT_OWNER_PID=$od wt new deadclean >/dev/null 2>&1
  WT_OWNER_PID=$ox wt new deaddirty >/dev/null 2>&1
  WT_OWNER_PID=$ox wt new deadcommit >/dev/null 2>&1
  echo x > "$wtdir/deaddirty/f"
  WT_OWNER_PID=$ox wt new hidden >/dev/null 2>&1
  git -C "$wtdir/hidden" config status.showUntrackedFiles no
  echo x > "$wtdir/hidden/untracked"
  WT_OWNER_PID=$od wt new envfile >/dev/null 2>&1
  printf '.env\nnode_modules/\n' >> "$repo/.git/info/exclude"
  echo s > "$wtdir/envfile/.env"
  WT_OWNER_PID=$od wt new oddnames >/dev/null 2>&1
  printf 'build\n-n\n' >> "$repo/.git/info/exclude"
  echo s > "$wtdir/oddnames/build"; echo s > "$wtdir/oddnames/-n"
    WT_OWNER_PID=$od wt new modules >/dev/null 2>&1
  mkdir -p "$wtdir/modules/node_modules/x"; echo s > "$wtdir/modules/node_modules/x/i.js"
  git -C "$wtdir/deadcommit" commit -q --allow-empty -m only-here
  gone "$od"; gone "$ox"
  # Claude Code's own format, owner gone.
  git worktree add -q -b worktree-claude "$wtdir/claude" HEAD --lock \
    --reason "claude session claude (pid 999999 start Tue Nov  3 06:00:17 2026)"
  # No owner recorded: fresh one waits out the grace period, old one does not.
  git worktree add -q -b worktree-fresh "$wtdir/fresh" HEAD
  git worktree add -q -b worktree-old "$wtdir/old" HEAD
  touch -t 202601010000 "$wtdir/old"
  # Directory deleted by hand.
  owner; ov=$OWNER
  WT_OWNER_PID=$ov wt new vanished >/dev/null 2>&1; rm -rf "$wtdir/vanished"; gone "$ov"
  # Outside .claude/worktrees (codex-fleet style): never touched.
  git worktree add -q -b fleet/t1 "$work/fleet-t1" HEAD

  att=$(wt list --all --attention)
  check "list --attention: dirty and only-here commits, owner gone" \
    '[[ $att == *deaddirty*未提交改动* && $att == *deadcommit*"1 个未推送提交"* && $att != *deadclean* && $att != *alive* ]]'

  dry=$(wt sweep --dry-run)
  check "sweep --dry-run: deletes nothing" '[[ $dry == *"会删除：$wtdir/deadclean"* && -d $wtdir/deadclean ]]'

  log=$(wt sweep)
  check "sweep: live owner kept" '[[ -d $wtdir/alive ]]'
  check "sweep: gone owner, clean: removed" '[[ ! -e $wtdir/deadclean ]] && ! git show-ref -q --verify refs/heads/worktree-deadclean'
  check "sweep: Claude-format lock, gone: removed" '[[ ! -e $wtdir/claude ]]'
  check "sweep: gone owner, uncommitted change: kept and reported" '[[ -f $wtdir/deaddirty/f && $log == *"需要处理：$wtdir/deaddirty"* ]]'
  check "sweep: gone owner, commit only here: kept" '[[ -d $wtdir/deadcommit && $log == *"需要处理：$wtdir/deadcommit"* ]]'
  check "sweep: no owner, recent: kept" '[[ -d $wtdir/fresh ]]'
  check "sweep: no owner, old and clean: removed" '[[ ! -e $wtdir/old ]]'
  check "sweep: deleted directory only reported" '[[ $(git worktree list --porcelain | grep -c "^worktree .*/vanished$") == 1 && $log == *"需要处理："*vanished*"目录已不在"* ]]'
  check "sweep: Chinese task, live owner kept" '[[ -d $wtdir/alivecn ]]'
  check "sweep: untracked file hidden by config kept" '[[ -f $wtdir/hidden/untracked ]]'
  check "sweep: ignored .env kept" '[[ -f $wtdir/envfile/.env && $log == *envfile*"被忽略的文件"* ]]'
  check "sweep: ignored file named build or -n kept" '[[ -f $wtdir/oddnames/build && -f "$wtdir/oddnames/-n" ]]'
  check "sweep: only node_modules ignored: removed" '[[ ! -e $wtdir/modules ]]'
  check "sweep: worktree outside .claude/worktrees untouched" '[[ -d $work/fleet-t1 ]]'

  # --- sweep --mine (session end) ---
  owner; me=$OWNER
  WT_OWNER_PID=$me wt new mineclean >/dev/null 2>&1
  WT_OWNER_PID=$me wt new minedirty >/dev/null 2>&1
  echo x > "$wtdir/minedirty/f"
  git worktree add -q -b worktree-reused "$wtdir/reused" HEAD --lock \
    --reason "claude session reused (pid $me start Tue Nov  3 01:02:03 2026)"
  WT_OWNER_PID=$me wt sweep --mine >/dev/null
  check "sweep --mine: own clean worktree removed" '[[ ! -e $wtdir/mineclean ]]'
  check "sweep --mine: own dirty worktree kept" '[[ -f $wtdir/minedirty/f ]]'
  check "sweep --mine: other owners untouched" '[[ -d $wtdir/alive && -d $wtdir/fresh ]]'
  check "sweep --mine: same pid, other start time untouched" '[[ -d $wtdir/reused ]]'

  # --- ps unavailable: nobody is declared gone ---
  mkdir "$work/fakebin"; printf '#!/bin/sh\nexit 1\n' > "$work/fakebin/ps"; chmod +x "$work/fakebin/ps"
  PATH="$work/fakebin:$PATH" "$src/wt" sweep >/dev/null 2>&1; rc=$?
  check "sweep: ps unavailable, refuses and deletes nothing" '[[ $rc != 0 && -d $wtdir/reused && -d $wtdir/minedirty ]]'
  PATH="$work/fakebin:$PATH" WT_OWNER_PID=$me "$src/wt" new nops >/dev/null 2>&1; rc=$?
  check "new: refuses when the owner start time is unknown" '[[ $rc != 0 && ! -e $wtdir/nops ]]'
  exit $fail
) || fail=1
check "no directory left behind" '[[ ! -e $work ]]'

exit $fail
