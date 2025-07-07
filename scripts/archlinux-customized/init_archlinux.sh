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

# 以下内容待整理：


# TODO:解决wsl 控制台中无法按住ctrl左右移动光标的问题

# TODO:让将以下代码可以直接通过wsl命令在powershell中执行
##################################以下代码需要进入linux中执行######################################

# 太久没更新导致unknown trust可将/etc/pacman.conf中SigLevel = Never
# 更新keyring
sudo pacman -S archlinux-keyring

# 测速并启用国内源
pacman -S reflector
sudo reflector --sort rate --threads 100 -c China --save /etc/pacman.d/mirrorlist

# 安装base-devel。注意，fakeroot包不支持wsl系统，在弹出提示后记得选n
# TODO:自动选择
pacman -S base-devel

# 更新系统
pacman -Syu
# 添加用户
useradd -m -G wheel chuckie

# 将wheel组设为sudo的超级用户
sed -i '1i\## allow members of group wheel to execute any command without a password' /etc/sudoers
sed -i '2i\%wheel ALL=(ALL:ALL) NOPASSWD:ALL' /etc/sudoers
sed -i '3i\\n' /etc/sudoers

su chuckie

# # pwsh对archlinux的支持不好，暂不使用
# # 安装powershell
# # TODO:指定clone的目录
# git clone https://aur.archlinux.org/powershell-bin.git
# cd powershell-bin/
# # 使用fastgit加速
# # 用fastgit下载的文件大小与github下载的文件大小不一至，暂不知道为什么。谨慎使用fastgit
# # sed -i 's/github.com/download.fastgit.org/g' PKGBUILD
# # TODO:自动确认
# makepkg -si
# # 配置默认交互shell为powershell
# echo 'exec pwsh -nologo' > /home/chuckie/.bashrc

# 安装YAY
pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

# 安装starship主题
pacman -S starship
# 启用starship
New-Item $PROFILE.CurrentUserCurrentHost -ItemType File -Force
echo "Invoke-Expression (&starship init powershell)" >> (pwsh -command '$profile.CurrentUserCurrentHost')

# TODO:删除clone下来的安装文件

# 用于支持pycharm wsl功能, python包已默认安装
pacman -S rsync
pacman -S python-pip
# 为pip更换国内源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 为VSCode Remote Python提供code formatting
pip install -U autopep8
sudo pacman -Syu net-tools #ifconfig 等命令
##################################以上代码需要进入linux中执行######################################

arch config --default-user chuckie
# 下载常用包
