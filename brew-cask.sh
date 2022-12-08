#!/usr/bin/env bash

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
    google-cloud-sdk
    brave-browser
    firefox
    qingg
)

brew install --cask "${caskapps[@]}"
brew cleanup
