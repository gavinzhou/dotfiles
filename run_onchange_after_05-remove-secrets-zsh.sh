#!/bin/bash
# One-time cleanup (gavinzhou/dotfiles#16): ~/.secrets.zsh used to export MCP
# tokens into every shell, so every agent subprocess carried them. Nothing read
# those variables; Codex gets its MCP secrets from ~/.codex/config.toml. Remove
# the file only when it is the generated one; any other file is left alone.
set -euo pipefail

f="$HOME/.secrets.zsh"
if [[ -f $f ]] && head -n 1 "$f" | grep -q '^# Generated from 1Password (vault gavin, item "dotfiles/.secrets.zsh")'; then
  rm -f "$f"
  echo "dotfiles: removed the generated ~/.secrets.zsh" >&2
fi
