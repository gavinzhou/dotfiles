#!/usr/bin/env bash

# Install packages
apps=(
    awscli
    cfssl
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
    zsh-completions
    kubectl
    kubectx
    zoom
    helmfile
    clipy
    slack
    microsoft-teams    
)

brew install "${apps[@]}"

