#!/bin/bash
# Wrapper to run build scripts as user lfs with proper environment
# Usage: sudo bash run-as-lfs.sh <script>

SCRIPT="$1"

if [ -z "$SCRIPT" ]; then
    echo "Usage: sudo bash run-as-lfs.sh <script-path>"
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Must run as root: sudo bash $0 $1"
    exit 1
fi

sudo -u lfs env -i \
    HOME=/home/lfs \
    TERM="$TERM" \
    LFS=/mnt/lfs \
    LFS_TGT=x86_64-lfs-linux-gnu \
    PATH=/mnt/lfs/tools/bin:/usr/bin:/bin \
    CONFIG_SITE=/mnt/lfs/usr/share/config.site \
    MAKEFLAGS="-j$(nproc)" \
    LC_ALL=POSIX \
    /bin/bash "$SCRIPT"
