#!/bin/bash
# ============================================================
# DevForge Linux - Chroot Preparation (LFS Chapter 7)
# ============================================================
# Prepares and enters the chroot environment
# Must run as root: sudo bash 05-chroot.sh
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config/distro.conf"

if [ "$(id -u)" -ne 0 ]; then
    log_error "Must run as root: sudo bash $0"
    exit 1
fi

log_step "Preparing Chroot Environment"

# --- Change ownership to root ---
log_info "Changing ownership of LFS to root..."
chown -R root:root "$LFS"/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
    x86_64) chown -R root:root "$LFS/lib64" ;;
esac

# --- Create virtual kernel filesystems ---
log_info "Creating virtual kernel filesystem mount points..."
mkdir -pv "$LFS"/{dev,proc,sys,run}

# --- Mount virtual filesystems ---
log_info "Mounting virtual filesystems..."

# /dev
if ! mountpoint -q "$LFS/dev"; then
    mount -v --bind /dev "$LFS/dev"
fi

# /dev/pts
if ! mountpoint -q "$LFS/dev/pts"; then
    mount -vt devpts devpts -o gid=5,mode=0620 "$LFS/dev/pts"
fi

# /proc
if ! mountpoint -q "$LFS/proc"; then
    mount -vt proc proc "$LFS/proc"
fi

# /sys
if ! mountpoint -q "$LFS/sys"; then
    mount -vt sysfs sysfs "$LFS/sys"
fi

# /run
if ! mountpoint -q "$LFS/run"; then
    mount -vt tmpfs tmpfs "$LFS/run"
fi

# Symlink /dev/shm
if [ -h "$LFS/dev/shm" ]; then
    install -v -d -m 1777 "$LFS/$(readlink "$LFS/dev/shm")"
else
    mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
fi

log_ok "Virtual filesystems mounted"

# --- Copy build scripts into chroot ---
log_info "Copying build scripts into chroot..."
mkdir -pv "$LFS/devforge"
cp -rv "$SCRIPT_DIR"/../config "$LFS/devforge/"
cp -rv "$SCRIPT_DIR"/06-base-system.sh "$LFS/devforge/"
cp -rv "$SCRIPT_DIR"/07-system-config.sh "$LFS/devforge/"
cp -rv "$SCRIPT_DIR"/08-kernel.sh "$LFS/devforge/"

# --- Enter chroot ---
log_step "Entering Chroot Environment"
log_info "You are now inside the DevForge build environment."
log_info "Run: bash /devforge/06-base-system.sh"
echo ""

chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='[\[\033[01;31m\]DevForge-Chroot\[\033[00m\]] \w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    /bin/bash --login
