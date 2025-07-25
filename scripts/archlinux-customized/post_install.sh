#!/bin/bash

set -euo pipefail

# --- 配置 ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PKG_LIST="$SCRIPT_DIR/pkg_list.sh"

readonly USER_NAME="Chuckie"

export http_proxy="http://127.0.0.1:10808"
export https_proxy="http://127.0.0.1:10808"
export all_proxy="http://127.0.0.1:10808"
export HTTP_PROXY="http://127.0.0.1:10808"
export HTTPS_PROXY="http://127.0.0.1:10808"
export ALL_PROXY="http://127.0.0.1:10808"


# --- 函数 ---
install_yay() {

    readonly windows_cache_dir="/mnt/d/archlinux/yay"
    readonly linux_cache_dir="/home/$USER_NAME/.cache/"
    readonly yay_path="$linux_cache_dir/yay/yay-bin"
    # 解决权限问题，需要复制到用户目录
    mkdir -p "$linux_cache_dir"
    cp -r $windows_cache_dir $linux_cache_dir
    chown -R $USER_NAME:$USER_NAME $linux_cache_dir

    echo "🔧 编译并安装 yay..."
    # 切换到非 root 用户执行 makepkg
    # 使用 sudo -u 是正确的做法，而不是 su
    pushd "$yay_path" >/dev/null
    sudo -u "$USER_NAME" makepkg -si --noconfirm
    popd >/dev/null
    echo "✅ yay 安装成功。"
}


install_aur_pkgs() {
    local pkgs=("$@")

    echo "📦 开始安装 ${#pkgs[@]} 个 AUR 包..."
    # 使用 yay 安装，并指定缓存目录，确保离线
    # 同样，以非 root 用户身份运行
    sudo -u "$USER_NAME" yay -S --noconfirm --needed "${pkgs[@]}"
    echo "✅ AUR 包安装完成。"
}


install_pacman_pkgs() {

    local pkgs=("$@")
    echo "📦 开始从缓存安装 ${#pkgs[@]} 个 Pacman 包..."

    if [ "${#pkgs[@]}" -gt 0 ]; then
        pacman -Syu --noconfirm --needed "${pkgs[@]}"
    fi
    echo "✅ Pacman 包安装完成。"
}

create_user() {

    echo "👤 创建用户 '$USER_NAME' 并加入 'wheel' 组..."
    useradd -m -G wheel "$USER_NAME"
    # home目录为 init_chezmoi在外部创建的，这些需要修改权限
    chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME"

    echo "🔑 为用户 '$USER_NAME' 设置密码"
    echo "Chuckie: " | chpasswd
    echo "🔑 为用户 root 设置密码"
    echo "root: " | chpasswd
}

setup_sudo() {
    echo "🔐 配置 sudoers文件..."
    chmod 0440 /etc/sudoers
}

# --- 主逻辑 ---
main() {

    create_user $USER_NAME
    setup_sudo


    # keyring相关
    # 太久没更新导致unknown trust可将/etc/pacman.conf中SigLevel = Never
    pacman-key --init
    pacman-key --populate archlinux

    source "$PKG_LIST"

    install_pacman_pkgs "${PACMAN[@]}"
    chsh -s /usr/bin/zsh "$USER_NAME"
    install_yay
    install_aur_pkgs "${YAY[@]}"

    pacman -Syu --noconfirm

    echo "\n🎉 初始化完成！"
    echo "请注销 root，以新用户 '$username' 登录继续操作。"
}

main
