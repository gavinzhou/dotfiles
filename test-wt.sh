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
  WT_OWNER_PID=$o1 wt done a >/dev/null 2>&1
  check "done: unpushed commit pushed to origin" \
    '[[ $(git --git-dir="$work/origin.git" rev-parse worktree-a 2>/dev/null) == $(git rev-parse worktree-a 2>/dev/null || echo gone) ]] || git --git-dir="$work/origin.git" rev-parse -q --verify worktree-a >/dev/null'
  check "done: worktree removed" '[[ ! -e $wtdir/a && $(git worktree list | wc -l) -eq 1 ]]'
  check "done: local branch removed once it is on origin" '! git show-ref -q --verify refs/heads/worktree-a'
  check "done: empty .claude removed" '[[ ! -e $repo/.claude ]]'

  WT_OWNER_PID=$o1 wt new b >/dev/null 2>&1
  echo x > "$wtdir/b/f"
  WT_OWNER_PID=$o1 wt done b --discard >/dev/null 2>&1
  check "done --discard: removes a dirty worktree" '[[ ! -e $wtdir/b ]]'

  WT_OWNER_PID=$o1 wt new c >/dev/null 2>&1
  (cd "$wtdir/c" && WT_OWNER_PID=$o1 "$src/wt" done >/dev/null 2>&1)
  check "done: no argument means the current worktree" '[[ ! -e $wtdir/c ]]'

  # --- sweep ---
  owner; oa=$OWNER; owner; od=$OWNER; owner; ox=$OWNER
  WT_OWNER_PID=$oa wt new alive >/dev/null 2>&1
  WT_OWNER_PID=$od wt new deadclean >/dev/null 2>&1
  WT_OWNER_PID=$ox wt new deaddirty >/dev/null 2>&1
  WT_OWNER_PID=$ox wt new deadcommit >/dev/null 2>&1
  echo x > "$wtdir/deaddirty/f"
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
  WT_OWNER_PID=$od wt new vanished >/dev/null 2>&1; rm -rf "$wtdir/vanished"
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
  check "sweep: deleted directory pruned" '[[ $(git worktree list --porcelain | grep -c vanished) == 0 ]]'
  check "sweep: worktree outside .claude/worktrees untouched" '[[ -d $work/fleet-t1 ]]'

  # --- sweep --mine (session end) ---
  owner; me=$OWNER
  WT_OWNER_PID=$me wt new mineclean >/dev/null 2>&1
  WT_OWNER_PID=$me wt new minedirty >/dev/null 2>&1
  echo x > "$wtdir/minedirty/f"
  WT_OWNER_PID=$me wt sweep --mine >/dev/null
  check "sweep --mine: own clean worktree removed" '[[ ! -e $wtdir/mineclean ]]'
  check "sweep --mine: own dirty worktree kept" '[[ -f $wtdir/minedirty/f ]]'
  check "sweep --mine: other owners untouched" '[[ -d $wtdir/alive && -d $wtdir/fresh ]]'
  exit $fail
) || fail=1
check "no directory left behind" '[[ ! -e $work ]]'

exit $fail
