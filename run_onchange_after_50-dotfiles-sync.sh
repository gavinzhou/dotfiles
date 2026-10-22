#!/bin/bash
# Installs the daily dotfiles-sync job. Runs again whenever this file changes.
set -euo pipefail

bin="$HOME/.local/bin/dotfiles-sync"
plist="$HOME/Library/LaunchAgents/com.gavinzhou.dotfiles-sync.plist"
mkdir -p "$(dirname "$bin")" "$(dirname "$plist")" "$HOME/Library/Logs"

# Write to a temp file and rename: a running dotfiles-sync keeps reading the
# old file, so updating itself mid-run cannot corrupt it.
cat > "$bin.new" <<'EOF'
#!/bin/bash
# Daily: fetch dotfiles, apply new commits if all are signed and this Mac has
# no local edits, and send a notification when the Mac and the repo disagree.
# Log: ~/Library/Logs/dotfiles-sync.log
set -uo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin"
export MISE_GLOBAL_CONFIG_FILE="$HOME/.mise.toml"
# Tells the installer script not to restart this job while it is running.
export DOTFILES_SYNC_RUNNING=1

notes=()
note() { notes+=("$1"); echo "$(date '+%F %T') $1"; }

notify() {
  local msg
  msg=$(printf '%s；' "${notes[@]}")
  osascript -e "display notification \"${msg%；}\" with title \"dotfiles\"" >/dev/null 2>&1 || true
}

# The source is the working clone in ~/Code. Check it before running chezmoi
# or brew at all: both execute code from the repo (the prereqs hook, Brewfile),
# and only reviewed master may run, never a feature branch or uncommitted work.
src="$HOME/Code/gavin/dotfiles"
branch=$(git -C "$src" symbolic-ref --short HEAD 2>/dev/null)
if [[ $branch != master ]] || [[ -n $(git -C "$src" status --porcelain 2>&1) ]]; then
  note "dotfiles 仓库不在 master 或有未提交的文件，今天没有自动更新"
  notify
  exit 0
fi

# New commits on origin/master that are not SSH-signed by Gavin's 1Password
# key (~/.git_allowed_signers). Only signed commits are applied, so a stolen
# GitHub login alone cannot run code on this Mac. OpenPGP and X.509
# signatures are refused outright (GitHub signs its web merges with OpenPGP),
# and any git error makes the whole check fail.
count_unsigned() {
  local commits c n=0
  commits=$(git -C "$src" rev-list HEAD..origin/master) || return 1
  for c in $commits; do
    if git -C "$src" cat-file commit "$c" | grep '^gpgsig -----BEGIN SSH SIGNATURE-----$' >/dev/null &&
      git -C "$src" -c gpg.ssh.allowedSignersFile="$HOME/.git_allowed_signers" \
        -c gpg.program=/usr/bin/false -c gpg.x509.program=/usr/bin/false \
        verify-commit "$c" >/dev/null 2>&1; then
      continue
    fi
    n=$((n + 1))
  done
  echo "$n"
}

# Files edited on this Mac since the last apply: chezmoi status puts those in
# the first column (the second column is changes still waiting in the repo).
# Count before pulling.
if status=$(chezmoi status --exclude=scripts 2>/dev/null); then
  local_edits=$(grep -c '^[^ ]' <<<"$status")
else
  local_edits=-1
fi

if (( local_edits < 0 )); then
  note "chezmoi status 运行失败，今天没有自动更新"
elif (( local_edits > 0 )); then
  note "本机有 ${local_edits} 个配置文件被改过，没有自动更新。运行 chezmoi diff 查看"
elif ! git -C "$src" fetch --quiet origin master; then
  note "拉取 dotfiles 仓库失败"
elif ! unsigned=$(count_unsigned); then
  note "检查提交签名时出错，没有自动更新"
elif (( unsigned > 0 )); then
  note "仓库有 ${unsigned} 个新提交没有你的签名，没有自动更新。确认后在仓库里运行 git merge --ff-only origin/master，再运行 chezmoi apply"
elif ! git -C "$src" merge --ff-only --quiet origin/master; then
  note "合并仓库更新失败，没有自动更新"
elif ! chezmoi apply --no-tty; then
  note "自动更新失败，运行 chezmoi apply 查看原因"
fi

brewfile="$src/Brewfile"
# Shells set HOMEBREW_NO_AUTO_UPDATE, so refresh Homebrew's package list here.
brew update --quiet >/dev/null 2>&1 || note "brew update 失败"
extra=$(brew bundle cleanup --file="$brewfile" 2>/dev/null | grep -vE '^(Would|Run) ' | grep -c .)
if (( extra > 0 )); then
  note "有 ${extra} 项软件或 tap 不在 Brewfile 里。运行 brew bundle cleanup --file=${brewfile} 查看"
fi
if ! brew bundle check --no-upgrade --file="$brewfile" >/dev/null 2>&1; then
  note "Brewfile 里有软件没装上。运行 brew bundle --no-upgrade --file=${brewfile}"
fi

if (( ${#notes[@]} > 0 )); then
  notify
else
  echo "$(date '+%F %T') ok"
fi
EOF
chmod 755 "$bin.new"
mv -f "$bin.new" "$bin"

cat > "$plist.new" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gavinzhou.dotfiles-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>$bin</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>10</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/dotfiles-sync.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/dotfiles-sync.log</string>
</dict>
</plist>
EOF

label=com.gavinzhou.dotfiles-sync
if cmp -s "$plist.new" "$plist" && launchctl print "gui/$UID/$label" >/dev/null 2>&1; then
  rm -f "$plist.new"
  exit 0
fi
mv -f "$plist.new" "$plist"

# Restarting the job from inside itself would kill this apply. launchd loads
# the new plist at the next login instead.
if [[ -n ${DOTFILES_SYNC_RUNNING:-} ]]; then
  echo "dotfiles: dotfiles-sync schedule changed; it takes effect at next login" >&2
  exit 0
fi
launchctl bootout "gui/$UID/$label" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$plist"
