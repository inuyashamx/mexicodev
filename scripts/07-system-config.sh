#!/bin/bash
# ============================================================
# DevForge Linux - System Configuration (LFS Chapter 9)
# ============================================================
# Configures bootscripts, network, and system settings
# Run INSIDE chroot
# ============================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_step()  { echo -e "\n${GREEN}========== $1 ==========${NC}\n"; }

# ============================================================
# Network Configuration
# ============================================================
configure_network() {
    log_step "Configuring Network"

    # Hostname
    echo "devforge" > /etc/hostname

    cat > /etc/hosts << "EOF"
127.0.0.1  localhost
127.0.1.1  devforge
::1        localhost ip6-localhost ip6-loopback
ff02::1    ip6-allnodes
ff02::2    ip6-allrouters
EOF

    # Basic network config (DHCP via systemd-networkd or ifupdown)
    mkdir -pv /etc/network

    cat > /etc/network/interfaces << "EOF"
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

    # DNS resolver
    cat > /etc/resolv.conf << "EOF"
# DevForge Linux DNS
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

    log_ok "Network configured"
}

# ============================================================
# System clock and locale
# ============================================================
configure_locale() {
    log_step "Configuring Locale and Clock"

    cat > /etc/profile << "PROFILEEOF"
# DevForge Linux - System Profile

# Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Default editor
export EDITOR=vim

# Path
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

# History
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups

# Colors for ls
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'

# DevForge banner
if [ "$PS1" ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi
PROFILEEOF

    # inputrc for readline
    cat > /etc/inputrc << "EOF"
set horizontal-scroll-mode Off
set meta-flag On
set input-meta On
set convert-meta Off
set output-meta On
set bell-style none

"\eOd": backward-word
"\eOc": forward-word
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert
"\eOH": beginning-of-line
"\eOF": end-of-line
"\e[H": beginning-of-line
"\e[F": end-of-line
EOF

    # Shells
    cat > /etc/shells << "EOF"
/bin/sh
/bin/bash
EOF

    log_ok "Locale and shell configured"
}

# ============================================================
# DevForge branding
# ============================================================
configure_branding() {
    log_step "Applying DevForge Branding"

    # /etc/os-release
    cat > /etc/os-release << EOF
NAME="DevForge Linux"
VERSION="0.1.0 (Ignition)"
ID=devforge
ID_LIKE=lfs
VERSION_ID=0.1.0
PRETTY_NAME="DevForge Linux 0.1.0 (Ignition)"
HOME_URL="https://devforge.linux"
BUG_REPORT_URL="https://github.com/devforge-linux/issues"
EOF

    # /etc/lsb-release
    cat > /etc/lsb-release << EOF
DISTRIB_ID=DevForge
DISTRIB_RELEASE=0.1.0
DISTRIB_CODENAME=ignition
DISTRIB_DESCRIPTION="DevForge Linux 0.1.0"
EOF

    # MOTD - Message of the Day
    cat > /etc/motd << 'EOF'

   ____             _____
  |  _ \  _____   _|  ___|__  _ __ __ _  ___
  | | | |/ _ \ \ / / |_ / _ \| '__/ _` |/ _ \
  | |_| |  __/\ V /|  _| (_) | | | (_| |  __/
  |____/ \___| \_/ |_|  \___/|_|  \__, |\___|
                                   |___/
  Linux for Developers | v0.1.0 "Ignition"
  Built from scratch with LFS 12.2

EOF

    # Issue banner (login screen)
    cat > /etc/issue << 'EOF'
DevForge Linux 0.1.0 \n \l

EOF

    log_ok "Branding applied"
}

# ============================================================
# Sysvinit bootscripts
# ============================================================
configure_bootscripts() {
    log_step "Configuring Boot Scripts"

    # Basic /etc/inittab for SysVinit
    cat > /etc/inittab << "EOF"
id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S06:once:/sbin/sulogin
s1:1:respawn:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600
EOF

    # Clock config
    cat > /etc/sysconfig/clock << "EOF"
UTC=1
EOF

    log_ok "Boot scripts configured"
}

# ============================================================
# fstab
# ============================================================
configure_fstab() {
    log_step "Creating /etc/fstab"

    cat > /etc/fstab << "EOF"
# DevForge Linux - File System Table
# <device>     <mount>  <type>  <options>            <dump> <pass>
#
# NOTE: Update these entries for your actual disk layout
# when installing on real hardware or VM
#
/dev/sda2      /        ext4    defaults             1      1
/dev/sda1      /boot    ext2    defaults             0      2
#/dev/sda3     swap     swap    pri=1                0      0
proc           /proc    proc    nosuid,noexec,nodev  0      0
sysfs          /sys     sysfs  nosuid,noexec,nodev   0      0
devpts         /dev/pts devpts  gid=5,mode=620       0      0
tmpfs          /run     tmpfs   defaults             0      0
devtmpfs       /dev     devtmpfs mode=0755,nosuid    0      0
tmpfs          /dev/shm tmpfs   nosuid,nodev         0      0
cgroup2        /sys/fs/cgroup cgroup2 nosuid,noexec,nodev 0 0
EOF

    log_ok "fstab created (update device paths for your hardware)"
}

# ============================================================
# Main
# ============================================================
configure_network
configure_locale
configure_branding
configure_bootscripts
configure_fstab

log_step "System Configuration Complete!"
log_info "Next: bash /devforge/08-kernel.sh"
