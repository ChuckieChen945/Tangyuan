#!/bin/bash
#
# Arch Linux 系统重装备份、初始化与恢复管理脚本
#
# 使用方法:
#   ./arch_manager.sh backup    # 重装前：备份软件包到缓存目录
#   ./arch_manager.sh init      # 重装后：初始化系统、添加用户
#   ./arch_manager.sh restore   # 初始化后：从缓存离线安装所有包
#

set -euo pipefail

###################################################
# 全局配置
###################################################
# 缓存目录，用于存放下载的包和数据库
CACHE_DIR="/mnt/d/scoop/cache"

# 要创建的用户名
USER_NAME="chuckie"

# 包列表文件路径
PKG_LIST_FILE="./pkg_list.sh"

# yay-bin 的 AUR git 地址和本地克隆路径
YAY_GIT_URL="https://aur.archlinux.org/yay-bin.git"
YAY_CACHE_DIR="${CACHE_DIR}/yay-bin"

###################################################
# 助手函数
###################################################
log_info() {
    echo -e "INFO: $1"
}

log_error() {
    echo -e "ERROR: $1" >&2
    exit 1
}

check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log_error "此操作需要 root 权限。请使用 'sudo' 或以 root 用户身份运行。"
    fi
}

# 加载包列表
load_package_list() {
    if [[ ! -f "$PKG_LIST_FILE" ]]; then
        log_error "未找到包列表文件：$PKG_LIST_FILE"
    fi
    source "$PKG_LIST_FILE"
    log_info "成功加载包列表。"
}

###################################################
# 核心功能函数
###################################################

# --- 备份功能 ---
run_backup() {
    log_info "--- 开始执行备份任务 ---"
    check_root

    load_package_list

    # 1. 创建缓存目录
    log_info "确保缓存目录存在: ${CACHE_DIR}"
    mkdir -p "$CACHE_DIR"

    # 2. 同步 pacman 数据库
    log_info "同步 pacman 软件包数据库..."
    pacman -Sy --dbpath "$CACHE_DIR" --noconfirm

    # 3. 下载所有 pacman 包及其依赖
    log_info "下载官方源软件包及其所有依赖..."
    # -w, --downloadonly: 仅下载，不安装
    # -g, --groups: 将包组中的所有包都选中
    # --needed: 不重新下载已存在的包
    pacman -Sgw --noconfirm --needed --dbpath "$CACHE_DIR" "${PACMAN_PKGS[@]}"

    # 4. 克隆 yay-bin 仓库
    if [[ -d "$YAY_CACHE_DIR" ]]; then
        log_info "yay-bin 仓库已存在，跳过克隆。"
    else
        log_info "克隆 yay-bin 仓库到缓存目录..."
        git clone "$YAY_GIT_URL" "$YAY_CACHE_DIR"
    fi

    log_info "✅ 备份任务完成！软件包和 yay-bin 源码已存放在 ${CACHE_DIR}"
}

# --- 初始化功能 ---
run_init() {
    log_info "--- 开始执行系统初始化任务 ---"
    check_root

    # 1. 设置网络（优先 IPv4）
    log_info "配置网络以优先使用 IPv4..."
    echo 'precedence ::ffff:0:0/96 100' >/etc/gai.conf

    # 2. 配置 pacman 镜像源
    log_info "配置清华大学和浙江大学镜像源..."
    cat >/etc/pacman.d/mirrorlist <<EOF
Server = http://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
Server = http://mirrors.zju.edu.cn/archlinux/\$repo/os/\$arch
EOF

    # 3. 安全地修改 pacman.conf 设置缓存目录
    log_info "设置 pacman 缓存目录为 ${CACHE_DIR}..."
    if grep -q "^CacheDir" /etc/pacman.conf; then
        # 如果已存在 CacheDir 设置，则替换它
        sed -i "s|^CacheDir.*|CacheDir = ${CACHE_DIR}|" /etc/pacman.conf
    else
        # 如果不存在，则在 [options] 下添加
        sed -i "/\[options\]/a CacheDir = ${CACHE_DIR}" /etc/pacman.conf
    fi
    pacman -Sy # 应用新配置并同步数据库

    # 4. 安装必要的工具
    log_info "安装基础工具: sudo, chezmoi..."
    pacman -S --noconfirm --needed sudo chezmoi

    # 5. 添加用户
    log_info "添加用户: ${USER_NAME}..."
    if id "$USER_NAME" &>/dev/null; then
        log_info "用户 ${USER_NAME} 已存在。"
    else
        useradd -m -G wheel "$USER_NAME"
        log_info "请为新用户 '${USER_NAME}' 设置密码:"
        passwd "$USER_NAME"
        log_info "用户 ${USER_NAME} 创建并设置密码成功。"
    fi
    chown -R "${USER_NAME}:${USER_NAME}" "/home/${USER_NAME}"

    # 6. 配置 sudo (安全方式)
    log_info "为 wheel 组配置免密 sudo 权限..."
    SUDOERS_FILE="/etc/sudoers.d/10-wheel-nopasswd"
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >"$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
    log_info "sudo 权限已通过 ${SUDOERS_FILE} 配置。"

    log_info "✅ 初始化任务完成！"
}

# --- 恢复功能 ---
run_restore() {
    log_info "--- 开始执行软件包恢复任务 ---"
    check_root

    load_package_list

    # 1. 恢复 pacman 数据库
    log_info "从缓存恢复 pacman 数据库..."
    if ls "${CACHE_DIR}"/*.db &>/dev/null; then
        cp -f "${CACHE_DIR}"/*.db /var/lib/pacman/sync/
    else
        log_error "缓存目录 ${CACHE_DIR} 中未找到数据库文件(*.db)。请先运行备份或联网同步。"
    fi

    # 2. 安装所有 pacman 包
    log_info "开始从缓存离线安装官方源软件包..."
    # 将包列表作为整体传递给 pacman，效率更高
    pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}"
    log_info "✅ 官方源软件包安装完成。"

    # 3. 安装 yay
    log_info "开始编译并安装 yay..."
    if [[ ! -d "$YAY_CACHE_DIR" ]]; then
        log_error "未找到 yay-bin 源码目录: ${YAY_CACHE_DIR}。请先运行备份。"
    fi
    # 切换到非 root 用户执行 makepkg，这是必须的
    # 使用 bash -c 来执行一系列命令
    log_info "以用户 ${USER_NAME} 的身份编译和安装 yay..."
    sudo -u "$USER_NAME" bash -c "cd '$YAY_CACHE_DIR' && makepkg -si --noconfirm"
    log_info "✅ yay 安装完成。"

    # 4. 使用 yay 安装 AUR 包
    if [[ ${#YAY_PKGS[@]} -gt 0 ]]; then
        log_info "开始使用 yay 安装 AUR 软件包..."
        sudo -u "$USER_NAME" yay -S --noconfirm --needed "${YAY_PKGS[@]}"
        log_info "✅ AUR 软件包安装完成。"
    else
        log_info "没有需要安装的 AUR 包。"
    fi

    # 5. 启用 reflector 服务
    log_info "启用并启动 reflector.timer 以自动更新镜像列表..."
    systemctl enable --now reflector.timer

    # 6. 启动其他服务 (可选)
    log_info "启动 Docker 服务..."
    systemctl enable --now docker.service

    log_info "✅ 所有恢复任务完成！"
}

###################################################
# 主逻辑入口
###################################################
main() {
    case "${1:-}" in
    backup)
        run_backup
        ;;
    init)
        run_init
        ;;
    restore)
        run_restore
        ;;
    *)
        echo "用法: $0 {backup|init|restore}"
        exit 1
        ;;
    esac
}

main "$@"
