#!/bin/bash
#
# 描述: 重装系统前，下载所有官方源和 AUR 包至指定缓存目录。
# 用法: ./backup_pkgs.sh /path/to/your/cache
#

set -euo pipefail

# --- 配置 ---
readonly PKG_LIST="./pkg_list.sh"

# --- 函数 ---

# 打印日志
log() {
    echo "=> $1"
}

# 检查依赖项
check_deps() {
    local missing=0
    for cmd in git yay; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "❌ 错误: 命令 '$cmd' 未找到，请先安装。" >&2
            missing=1
        fi
    done
    if [[ $missing -eq 1 ]]; then
        exit 1
    fi
}

# 同步 Pacman 数据库
sync_pacman_db() {
    local cache_dir="$1"
    log "📦 同步 Pacman 软件包数据库..."
    sudo pacman -Sy --dbpath "$cache_dir" --noconfirm
}

# 下载 Pacman 包
download_pacman_pkgs() {
    local cache_dir="$1"
    shift
    local pkgs=("$@")

    log "📥 开始下载 ${#pkgs[@]} 个 Pacman 包及其依赖..."
    if sudo pacman -Sw --noconfirm --needed --dbpath "$cache_dir" "${pkgs[@]}"; then
        log "✅ 所有 Pacman 包下载成功。"
    else
        log "🚨 部分 Pacman 包下载失败。"
        return 1
    fi
}

# 下载 AUR 包
download_aur_pkgs() {
    local cache_dir="$1"
    shift
    local pkgs=("$@")

    log "📥 开始下载 ${#pkgs[@]} 个 AUR 包..."
    # 设置 yay 的缓存目录为我们的备份目录
    # -Swa: Sync, download-only, all (包括依赖)
    if sudo -u "$SUDO_USER" yay -Swa --aur --cachedir "$cache_dir" "${pkgs[@]}"; then
        log "✅ 所有 AUR 包下载成功。"
    else
        log "🚨 部分 AUR 包下载失败。"
        return 1
    fi
}

# --- 主逻辑 ---
main() {
    if [[ $# -eq 0 ]]; then
        echo "❌ 错误: 请提供缓存目录路径作为参数。"
        echo "   用法: $0 /path/to/your/cache"
        exit 1
    fi
    local cache_dir="$1"

    # 确保缓存目录存在
    mkdir -p "$cache_dir"

    # 检查根权限
    if [[ $EUID -ne 0 ]]; then
        echo "Script must be run with sudo"
        exit 1
    fi

    check_deps

    if [[ ! -f "$PKG_LIST" ]]; then
        echo "❌ 未找到包列表文件：$PKG_LIST" >&2
        exit 1
    fi
    source "$PKG_LIST"

    sync_pacman_db "$cache_dir"
    download_pacman_pkgs "$cache_dir" "${PACMAN[@]}"
    download_aur_pkgs "$cache_dir" "${YAY[@]}"

    log "🌀 克隆 yay-bin 以便在新系统上引导安装..."
    git clone https://aur.archlinux.org/yay-bin.git "$cache_dir/yay-bin"

    log "\n🎉 所有备份任务完成！缓存目录: $cache_dir"
}

main "$@"
