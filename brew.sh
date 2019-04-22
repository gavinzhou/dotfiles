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
)

caskapps=(
    appcleaner
    visual-studio-code
    google-chrome
    google-japanese-ime
    cmd-eikana
    iterm2
    qq
    clipy
    slack
    insomnia
    keybase
    google-cloud-sdk
)

caskfont=(
    font-source-code-pro
)

brew install "${apps[@]}"
brew cask install "${caskapps[@]}"
brew cask install "${caskfont[@]}"
brew cleanup
