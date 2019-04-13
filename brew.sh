#!/usr/bin/env bash

brew update
brew upgrade

# Install packages
apps=(
    awscli
    n
    wget
    zsh-completions
    cfssl
    circleci
    golang
    httpie
    ccat
    gzip
    fd
    optipng
    zsh
    hub
    ripgrep
    git-secrets
    gnupg
    pinentry-mac
    peco
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
