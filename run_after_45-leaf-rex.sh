#!/bin/bash
# Adds leaf to Rex's command palette. Runs on every apply, because Rex may be
# installed after the first apply and leaf's path can change (it moved from
# ~/.local/bin to Homebrew once, which left Rex pointing at a missing file).
set -euo pipefail

eval "$(/opt/homebrew/bin/brew shellenv)"

rex_dir="$HOME/Library/Application Support/com.superlogical.rex"
config="$HOME/.config/rex/init.lua"
plugin="$HOME/.config/rex/plugins/leaf/init.lua"

leaf=$(command -v leaf 2>/dev/null || true)
if [[ -z $leaf ]]; then
  exit 0 # the Brewfile installs it; next apply picks it up
fi
if [[ ! -d $rex_dir ]]; then
  echo "dotfiles: Rex isn't installed; after installing it, run 'chezmoi apply' to add leaf to Rex" >&2
  exit 0
fi

# Already set up with this leaf: nothing to do (installing again reloads Rex).
# Match the whole line leaf writes, so a comment or another plugin's line with
# the same path doesn't count.
if [[ -f $plugin && -f $config ]] &&
  grep -qxF "dofile(\"$plugin\").setup({ bin = { \"$leaf\" } })" "$config"; then
  exit 0
fi

# leaf reloads Rex through the rex CLI, which lives inside the Rex server app.
PATH="$PATH:$rex_dir/RexServer/Versions/Current/Rex Server.app/Contents/MacOS"
"$leaf" rex install ||
  echo "dotfiles: 'leaf rex install' failed; run 'chezmoi apply' later to retry" >&2
