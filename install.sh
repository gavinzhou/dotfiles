#!/usr/bin/env bash

# Get current dir (so run this script from anywhere)
export DOTFILES_DIR
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Update dotfiles itself first
#[ -d "$DOTFILES_DIR/.git" ] && git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin master

# Package managers & packages
. "$DOTFILES_DIR/scripts/script.sh"
. "$DOTFILES_DIR/scripts/brew.sh"
. "$DOTFILES_DIR/scripts/macos.sh"
zsh "$DOTFILES_DIR/scripts/prezto.zsh"

# sync dot file to home directory
function doIt() {
    rsync   .zshrc \
        .aliases \
        .gitconfig \
        .zpreztorc \
        .digrc \
        ~/;
}
sudo -v
doIt;
mkdir -p ${HOME}/go
