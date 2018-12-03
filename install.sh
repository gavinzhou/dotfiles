#!/usr/bin/env bash

# Get current dir (so run this script from anywhere)

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

export DOTFILES_DIR
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Update dotfiles itself first
#[ -d "$DOTFILES_DIR/.git" ] && git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin master

# Package managers & packages
. "$DOTFILES_DIR/scripts/script.sh"
. "$DOTFILES_DIR/scripts/brew.sh"
zsh "$DOTFILES_DIR/scripts/prezto.zsh"

# git config
ln -s .gitconfig ~/.gitconfig
mkdir -p ${HOME}/go
