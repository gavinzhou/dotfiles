#!/usr/bin/env bash

# Install packages
apps=(
    awscli
    hub
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
)

brew install "${apps[@]}"

