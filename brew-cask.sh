#!/usr/bin/env bash

caskapps=(
    google-chrome
    visual-studio-code
    google-japanese-ime
    wechat
    google-cloud-sdk
    iina
    microsoft-edge
    squirrel
    karabiner-elements
)

brew install --cask "${caskapps[@]}"
brew cleanup
