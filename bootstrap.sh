#!/usr/bin/env bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

sudo -v

brew update
brew upgrade

bash "macos.sh"

# Package managers & packages
export PATH="/opt/homebrew/bin:$PATH"
bash "brew.sh"
bash "brew-cask.sh"


# sync dot file to home directory
function doIt() {
    rsync   .zshrc \
        .aliases \
        .gitconfig \
        .zpreztorc \
        .digrc \
        ~/;
}
doIt;

zsh "prezto.zsh"

sudo spctl --master-disable
cp com.keyboard.macos.plist ~/Library/LaunchAgents/
cp com.tapbehavior.macos.plist ~/Library/LaunchAgents/
rm ~/Library/Preferences/com.googlecode.iterm2.plist
cp com.googlecode.iterm2.plist ~/Library/Preferences/
