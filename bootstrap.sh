#!/usr/bin/env bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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
        ~/.gnupg/;
}
sudo -v
doIt;
mkdir -p ${HOME}/go

\curl -sSL https://get.rvm.io | bash
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
go get github.com/brancz/gojsontoyaml

zsh "prezto.zsh"

sudo spctl --master-disable
