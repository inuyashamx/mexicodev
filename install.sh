#!/bin/bash
# MexicoDev Linux - Automated Installer
# Usage: sudo bash install.sh /dev/sdX
# Run from any Linux live USB

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

DISK="$1"
RELEASE_URL="https://github.com/inuyashamx/mexicodev/releases/download/v0.1.0/mexicodev-0.1.0-x86_64.tar.xz"

if [ -z "$DISK" ]; then
    echo -e "${RED}Usage: sudo bash install.sh /dev/sdX${NC}"
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Run as root: sudo bash install.sh $DISK${NC}"
    exit 1
fi

echo -e "${BLUE}"
echo "  __  __            _           ____"
echo " |  \/  | _____  __(_) ___ ___ |  _ \\  _____   __"
echo " | |\\/| |/ _ \\ \\/ /| |/ __/ _ \\| | | |/ _ \\ \\ / /"
echo " | |  | |  __/>  < | | (_| (_) | |_| |  __/\\ V /"
echo " |_|  |_|\\___/_/\\_\\|_|\\___\\___/|____/ \\___| \\_/"
echo -e "${NC}"
echo "MexicoDev Linux Installer v0.1.0"
echo "================================"
echo ""
echo -e "${RED}WARNING: This will ERASE all data on ${DISK}${NC}"
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo -e "\n${GREEN}[1/5] Partitioning ${DISK}...${NC}"
# Create MBR partition table
parted -s "$DISK" mklabel msdos
parted -s "$DISK" mkpart primary ext2 1MiB 512MiB
parted -s "$DISK" mkpart primary ext4 512MiB 100%
parted -s "$DISK" set 1 boot on

# Format
mkfs.ext2 -F "${DISK}1"
mkfs.ext4 -F "${DISK}2"

echo -e "${GREEN}[2/5] Mounting...${NC}"
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot

echo -e "${GREEN}[3/5] Downloading MexicoDev...${NC}"
if [ -f "mexicodev-0.1.0-x86_64.tar.xz" ]; then
    echo "Using local tarball..."
    tar xpf mexicodev-0.1.0-x86_64.tar.xz -C /mnt
else
    wget -O - "$RELEASE_URL" | tar xJpf - -C /mnt
fi

echo -e "${GREEN}[4/5] Updating fstab...${NC}"
ROOT_UUID=$(blkid -s UUID -o value "${DISK}2")
BOOT_UUID=$(blkid -s UUID -o value "${DISK}1")

cat > /mnt/etc/fstab << EOF
# MexicoDev Linux - File System Table
UUID=${ROOT_UUID}  /       ext4  defaults  1 1
UUID=${BOOT_UUID}  /boot   ext2  defaults  0 2
proc               /proc   proc  nosuid,noexec,nodev  0 0
sysfs              /sys    sysfs nosuid,noexec,nodev   0 0
devpts             /dev/pts devpts gid=5,mode=620      0 0
tmpfs              /run    tmpfs  defaults              0 0
devtmpfs           /dev    devtmpfs mode=0755,nosuid    0 0
EOF

echo -e "${GREEN}[5/5] Installing GRUB...${NC}"
mount --bind /dev /mnt/dev
mount -t proc proc /mnt/proc
mount -t sysfs sysfs /mnt/sys

# Try grub-install if available
if chroot /mnt /bin/bash -c "which grub-install" 2>/dev/null; then
    chroot /mnt grub-install "$DISK"
    chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "GRUB not in rootfs. Installing from live system..."
    if which grub-install 2>/dev/null; then
        grub-install --root-directory=/mnt "$DISK"
    else
        echo -e "${RED}GRUB not available. Install manually after reboot.${NC}"
        echo "You can use: grub-install --root-directory=/mnt $DISK"
    fi

    # Create grub.cfg with UUIDs
    mkdir -p /mnt/boot/grub
    cat > /mnt/boot/grub/grub.cfg << GRUBEOF
set default=0
set timeout=5
set menu_color_normal=cyan/blue
set menu_color_highlight=white/blue

menuentry "MexicoDev Linux 0.1.0" {
    search --no-floppy --fs-uuid --set=root ${ROOT_UUID}
    linux /boot/vmlinuz-6.10.5-mexicodev root=UUID=${ROOT_UUID} ro quiet
}

menuentry "MexicoDev Linux 0.1.0 (Recovery)" {
    search --no-floppy --fs-uuid --set=root ${ROOT_UUID}
    linux /boot/vmlinuz-6.10.5-mexicodev root=UUID=${ROOT_UUID} ro single
}
GRUBEOF
fi

# Rename kernel if needed
if [ -f /mnt/boot/vmlinuz-6.10.5-devforge ]; then
    mv /mnt/boot/vmlinuz-6.10.5-devforge /mnt/boot/vmlinuz-6.10.5-mexicodev
fi

# Cleanup
umount -R /mnt

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN} MexicoDev Linux installed!${NC}"
echo -e "${GREEN} Remove the live USB and reboot.${NC}"
echo -e "${GREEN}================================${NC}"
