#!/bin/bash
#
# 描述: 重装系统前，下载所有官方源和 AUR 包至指定缓存目录。
#

set -euo pipefail

# --- 配置 ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PKG_LIST="$SCRIPT_DIR/pkg_list.sh"

source "$PKG_LIST"

# export http_proxy='http://127.0.0.1:10808'
# export https_proxy='http://127.0.0.1:10808'
# export all_proxy='http://127.0.0.1:10808'
# export HTTP_PROXY='http://127.0.0.1:10808'
# export HTTPS_PROXY='http://127.0.0.1:10808'
# export ALL_PROXY='http://127.0.0.1:10808'

# --- 函数 ---


# 下载 Pacman 包
download_pacman_pkgs() {

    echo "📥 开始下载 Pacman 包及其依赖..."

    ALL_PACKAGES=()

    for item in "${PACMAN[@]}"; do
        # 检查是否是一个软件组
        if pacman -Sg "$item" &>/dev/null; then
            # 是组，展开为组内的包
            GROUP_PKGS=$(pacman -Sg "$item" | awk '{print $2}')
            ALL_PACKAGES+=($GROUP_PKGS)
        else
            # 是单独包
            ALL_PACKAGES+=("$item")
        fi
    done

    # 去重（需要 GNU sort 和 uniq）
    # UNIQUE_PACKAGES=($(printf "%s\n" "${ALL_PACKAGES[@]}" | sort -u))

    # 下载所有包
    if [ "${#ALL_PACKAGES[@]}" -gt 0 ]; then
        sudo pacman -S --downloadonly --noconfirm --needed "${ALL_PACKAGES[@]}"
    fi
}

# 下载 AUR 包
download_aur_pkgs() {

    echo "📥 开始下载 AUR 包..."
    # 设置 yay 的缓存目录为我们的备份目录
    # -Swa: Sync, download-only, all (包括依赖)
    # if sudo -u "$SUDO_USER" yay -Swa --aur  "${pkgs[@]}"; then

    if [ "${#YAY[@]}" -gt 0 ]; then
        if yay -S --downloadonly --noconfirm --needed "${YAY[@]}"; then
            echo "✅ 所有 AUR 包下载成功。"
        else
            echo "🚨 部分 AUR 包下载失败。"
            return 1
        fi
    fi
}

# --- 主逻辑 ---
main() {


    download_pacman_pkgs
    download_aur_pkgs

    # docker数据不能在NTFS上跑，只能每次重装系统前复制备份
    echo "📂 开始备份 Docker 数据..."
    # TODO: 增量备份，加快速度
    cp -r /var/lib/docker/ /mnt/d/archlinux/

    echo "\n🎉 所有备份任务完成！"
}

main
