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
    neovim
    python
    screenfetch
    archlinuxcn-keyring # 导入 Arch Linux CN 的 GPG 密钥
)

# AUR (Arch User Repository) 包
YAY=(
    v2rayn-bin # v2rayN
    yay-bin
)
