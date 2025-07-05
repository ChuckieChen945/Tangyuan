#!/bin/bash
#
# 描述: 新安装 Arch Linux 后，进行基础配置，包括镜像、Pacman缓存和用户创建。
# 用法: sudo ./init_archlinux.sh <username> /path/to/your/cache
#

set -euo pipefail

# --- 函数 ---
log() {
    echo "=> $1"
}

setup_network_prefs() {
    log "🔧 配置网络，优先使用 IPv4..."
    echo 'precedence ::ffff:0:0/96 100' >/etc/gai.conf
}

setup_mirrors() {
    log "🔧 配置 Pacman 清华/浙大镜像源..."
    cat >/etc/pacman.d/mirrorlist <<EOF
Server = http://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = http://mirrors.zju.edu.cn/archlinux/\$repo/os/\$arch
EOF
}

setup_pacman_conf() {
    local cache_dir="$1"
    log "🔧 配置 Pacman 使用缓存目录: $cache_dir"
    # 使用 sed 修改，而不是覆盖整个文件，更加安全
    # 1. 如果 CacheDir 已存在，替换它
    # 2. 如果不存在，在 [options] 后添加
    if grep -q "^CacheDir" /etc/pacman.conf; then
        sed -i "s|^CacheDir.*|CacheDir = $cache_dir|" /etc/pacman.conf
    else
        sed -i "/^\[options\]/a CacheDir = $cache_dir" /etc/pacman.conf
    fi
    # 启用颜色
    sed -i "s/^#Color/Color/" /etc/pacman.conf
}

create_user() {
    local username="$1"
    log "👤 创建用户 '$username' 并加入 'wheel' 组..."
    useradd -m -G wheel "$username"

    log "🔑 为用户 '$username' 设置密码:"
    echo "Chuckie: " | chpasswd

    chown -R "${username}:${username}" "/home/${username}"
}

setup_sudo() {
    log "🔐 配置 'wheel' 组的 sudo 免密权限..."
    # 使用 drop-in 文件是修改 sudoers 的标准、安全做法
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >/etc/sudoers.d/99-wheel-nopasswd
    chmod 0440 /etc/sudoers.d/99-wheel-nopasswd
}

# --- 主逻辑 ---
main() {
    if [[ $# -ne 2 ]]; then
        echo "❌ 错误: 请提供用户名和缓存目录路径。"
        echo "   用法: $0 <username> /path/to/your/cache"
        exit 1
    fi

    if [[ "$EUID" -ne 0 ]]; then
        echo "❌ 错误: 此脚本必须以 root 权限运行。" >&2
        exit 1
    fi

    local username="$1"
    local cache_dir="$2"

    setup_network_prefs
    setup_mirrors

    log "📦 安装基础工具: sudo, chezmoi..."
    pacman -Syu --noconfirm sudo chezmoi

    setup_pacman_conf "$cache_dir"
    create_user "$username"
    setup_sudo

    log "\n🎉 初始化完成！"
    log "请注销 root，以新用户 '$username' 登录继续操作。"
}

main "$@"
