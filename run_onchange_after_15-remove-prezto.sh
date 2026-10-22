#!/bin/bash
# One-time cleanup on Macs that used Prezto: ~/.zlogin was a symlink into
# ~/.zprezto/runcoms. Remove it only when it is exactly that; any other
# ~/.zlogin is left alone. (.zshenv and .zprofile are now chezmoi files.)
set -euo pipefail

f="$HOME/.zlogin"
if [[ -L $f && $(readlink "$f") == "$HOME/.zprezto/runcoms/"* ]]; then
  rm -f "$f"
  echo "dotfiles: removed the Prezto symlink ~/.zlogin" >&2
fi
