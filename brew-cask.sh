#!/usr/bin/env bash

caskapps=(
    google-chrome
    visual-studio-code
    google-japanese-ime
    cmd-eikana
    clipy
    slack
    keybase
    google-cloud-sdk
    wechat
    microsoft-teams
    google-cloud-sdk
    brave-browser
    firefox
    warp
)

brew install --cask "${caskapps[@]}"
brew cleanup
