#!/usr/bin/env bash

caskapps=(
    google-chrome
    visual-studio-code
    google-japanese-ime
    wechat
    google-cloud-sdk
    firefox
    iina
    microsoft-edge
)

brew install --cask "${caskapps[@]}"
brew cleanup
