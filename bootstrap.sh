#!/usr/bin/env bash

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Package managers & packages
. "brew.sh"
. "macos.sh"


# sync dot file to home directory
function doIt() {
    rsync   .zshrc \
        .aliases \
        .gitconfig \
        .zpreztorc \
        .digrc \
        ~/;
    rsync gpg-agent.conf \
        ~/.gnupg;
}
sudo -v
doIt;
mkdir -p ${HOME}/go

\curl -sSL https://get.rvm.io | bash

zsh "prezto.zsh"
