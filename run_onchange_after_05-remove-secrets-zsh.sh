#!/bin/bash
# One-time cleanup (gavinzhou/dotfiles#16): ~/.secrets.zsh used to export MCP
# tokens into every shell, so every agent subprocess carried them. Nothing read
# those variables; Codex gets its MCP secrets from ~/.codex/config.toml. Remove
# the file only when it is the generated one; any other file is left alone.
set -euo pipefail

f="$HOME/.secrets.zsh"
[[ -f $f ]] || exit 0
# Fail when it cannot be read, so chezmoi runs this again next time.
[[ -r $f ]] || { echo "dotfiles: cannot read ~/.secrets.zsh; not removed" >&2; exit 1; }
first=
IFS= read -r first < "$f" || true
if [[ $first == '# Generated from 1Password (vault gavin, item "dotfiles/.secrets.zsh")'* ]]; then
  rm -f "$f"
  echo "dotfiles: removed the generated ~/.secrets.zsh. Terminals and agent apps already open still carry SLACK_MCP_TOKEN / STITCH_API_KEY; restart them." >&2
fi
