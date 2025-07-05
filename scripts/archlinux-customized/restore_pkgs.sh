#!/bin/bash
#
# 描述: 从缓存目录离线安装所有 Pacman 和 AUR 包。
# 用法: ./restore_pkgs.sh <username> /path/to/your/cache
#

set -euo pipefail

# --- 配置 ---
readonly PKG_LIST="./pkg_list.sh"

# --- 函数 ---
log() {
    echo "=> $1"
}

restore_pacman_db() {
    local cache_dir="$1"
    log "📀 恢复 Pacman 数据库..."
    if ls "$cache_dir"/*.db &>/dev/null; then
        log "  从缓存目录 $cache_dir 复制数据库文件。"
        sudo cp "$cache_dir"/*.db /var/lib/pacman/sync/
    else
        log "  缓存中未找到数据库文件，将联网同步。"
        sudo pacman -Sy --noconfirm
    fi
}

install_pacman_pkgs() {
    shift
    local pkgs=("$@")
    log "📦 开始从缓存安装 ${#pkgs[@]} 个 Pacman 包..."
    sudo pacman -S --noconfirm --needed "${pkgs[@]}"
    log "✅ Pacman 包安装完成。"
}

install_yay() {
    local username="$1"
    local cache_dir="$2"
    local yay_path="$cache_dir/yay-bin"

    if [[ ! -d "$yay_path" ]]; then
        log "❌ 未找到 yay-bin 目录: $yay_path"
        return 1
    fi

    log "🔧 编译并安装 yay..."
    # 切换到非 root 用户执行 makepkg
    # 使用 sudo -u 是正确的做法，而不是 su
    pushd "$yay_path" >/dev/null
    sudo -u "$username" makepkg -si --noconfirm
    popd >/dev/null
    log "✅ yay 安装成功。"
}

install_aur_pkgs() {
    local username="$1"
    local cache_dir="$2"
    shift 2
    local pkgs=("$@")

    log "📦 开始安装 ${#pkgs[@]} 个 AUR 包..."
    # 使用 yay 安装，并指定缓存目录，确保离线
    # 同样，以非 root 用户身份运行
    sudo -u "$username" yay -S --noconfirm --needed --cachedir "$cache_dir" "${pkgs[@]}"
    log "✅ AUR 包安装完成。"
}

setup_services() {
    log "⚙️ 启用并启动 reflector 定时器..."
    sudo systemctl enable --now reflector.timer
    log "⚙️ 启用 Docker 服务..."
    sudo systemctl enable docker.service
}

# --- 主逻辑 ---
main() {
    if [[ $# -ne 2 ]]; then
        echo "❌ 错误: 请提供用户名和缓存目录路径。"
        echo "   用法: $0 <username> /path/to/your/cache"
        exit 1
    fi

    # 此脚本应该由新创建的用户通过 sudo 执行
    # if [[ "$EUID" -eq 0 ]]; then
    #     echo "❌ 错误: 请不要以 root 用户直接运行此脚本。" >&2
    #     echo "   请以新用户身份运行: sudo $0 $*" >&2
    #     exit 1
    # fi

    local username="$1"
    local cache_dir="$2"

    if [[ ! -f "$PKG_LIST" ]]; then
        echo "❌ 未找到包列表文件：$PKG_LIST" >&2
        exit 1
    fi
    source "$PKG_LIST"

    restore_pacman_db "$cache_dir"
    install_pacman_pkgs "${PACMAN[@]}"
    install_yay "$username" "$cache_dir"
    install_aur_pkgs "$username" "$cache_dir" "${YAY[@]}"
    setup_services

    log "\n🎉 所有包装完毕！建议执行 'sudo pacman -Syu' 全面更新系统。"
}

main "$@"
