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
    openvpn
    azure-cli
    zoom
    tanka
    jsonnet
    helm
    eksctl
    helmfile
    cmd-eikana
    clipy
    slack
    keybase
    microsoft-teams    
)

brew install "${apps[@]}"

