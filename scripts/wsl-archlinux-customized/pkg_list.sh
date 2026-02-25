#!/bin/bash

# Pacman 官方源包
PACMAN=(
    base-devel
    pacman-contrib
    reflector
    zsh
    zsh-completions
    starship
    which
    wget
    zoxide
    git
    sudo
    docker
    docker-buildx
    docker-compose
    exa
    neovim
    python
    screenfetch
    archlinuxcn-keyring # 导入 Arch Linux CN 的 GPG 密钥
    yay # from archlinuxcn
    xray # from archlinuxcn
)

# AUR (Arch User Repository) 包
YAY=(
)
