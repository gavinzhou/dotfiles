#!/usr/bin/env bash

brew update
brew upgrade

# Install packages
apps=(
    awscli
    ccat
    cfssl
    circleci
    fd
    git-secrets
    gnupg
    golang
    gzip
    httpie
    hub
    jq
    n
    optipng
    peco
    pinentry-mac
    ripgrep
    wget
    zsh
    zsh-completions
    kubectl
    kubectx
    homebrew/cask
    openvpn
    azure-cli
    zoom
)

caskapps=(
    google-chrome
    appcleaner
    visual-studio-code
    google-japanese-ime
    cmd-eikana
    iterm2
    clipy
    slack
    insomnia
    keybase
    google-cloud-sdk
    wechat
    microsoft-teams
)

#caskfont=(
#    font-source-code-pro
#)

brew install "${apps[@]}"
brew install --cask "${caskapps[@]}"
#brew install "${caskapps[@]}"
#brew cask install "${caskfont[@]}"
brew cleanup
