#!/bin/bash
# Agent workspace. Runs on every apply, so each step checks before acting and
# the memory clone is retried until gh is logged in.
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"

# Code lives in ~/Code/<group>/<repo>
for group in pabbit poincare dbf pacport-ops gavin pp01a _archive _vendor; do
  mkdir -p "$HOME/Code/$group"
done

# Claude Code CLI (Codex comes from the Brewfile). The installer URL is
# sometimes rate limited; a failure must not stop the rest of the apply, and
# this script runs again on the next apply.
if [[ ! -x $HOME/.local/bin/claude ]]; then
  curl -fsSL --retry 5 --retry-delay 10 https://claude.ai/install.sh | bash ||
    echo "dotfiles: Claude Code install failed; run 'chezmoi apply' later to retry" >&2
fi

# Shared agent memory (private repo)
if [[ ! -d $HOME/.agents/memory/.git ]]; then
  if gh auth status >/dev/null 2>&1; then
    mkdir -p "$HOME/.agents"
    gh repo clone gavinzhou/memory "$HOME/.agents/memory"
  else
    echo "dotfiles: run 'gh auth login', then 'chezmoi apply' to clone the memory repo" >&2
  fi
fi
