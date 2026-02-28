#!/bin/bash
# Run a script inside chroot - called from Windows/WSL side
# Usage: wsl bash -c "sudo bash /mnt/c/.../chroot-run.sh <script-inside-chroot>"
SCRIPT="$1"
if [ -z "$SCRIPT" ]; then echo "Usage: $0 <script>"; exit 1; fi

# Ensure mounts
mountpoint -q /mnt/lfs/dev  || mount -v --bind /dev /mnt/lfs/dev
mountpoint -q /mnt/lfs/dev/pts || mount -vt devpts devpts -o gid=5,mode=0620 /mnt/lfs/dev/pts
mountpoint -q /mnt/lfs/proc || mount -vt proc proc /mnt/lfs/proc
mountpoint -q /mnt/lfs/sys  || mount -vt sysfs sysfs /mnt/lfs/sys
mountpoint -q /mnt/lfs/run  || mount -vt tmpfs tmpfs /mnt/lfs/run

chroot /mnt/lfs /usr/bin/env -i \
    HOME=/root TERM=xterm \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    /bin/bash "$SCRIPT"
