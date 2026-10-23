#!/bin/bash
# chezmoi runs this before every command (hooks.read-source-state.pre), so the
# already-installed path must stay fast and silent.
set -euo pipefail

brew_bin=/opt/homebrew/bin/brew

if [[ ! -x $brew_bin ]]; then
  echo "dotfiles: installing Homebrew (asks for your password once)" >&2
  sudo -v
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ ! -d /Applications/1Password.app ]] || [[ ! -x /opt/homebrew/bin/op ]]; then
  echo "dotfiles: installing 1Password and its CLI" >&2
  "$brew_bin" install --cask 1password 1password-cli
fi

# dot_claude and dot_codex merge JSON/TOML with these while files are applied,
# before the Brewfile script runs.
if [[ ! -x /opt/homebrew/bin/jq ]] || [[ ! -x /opt/homebrew/bin/yq ]]; then
  echo "dotfiles: installing jq and yq" >&2
  "$brew_bin" install jq yq
fi
