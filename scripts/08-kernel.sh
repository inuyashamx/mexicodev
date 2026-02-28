#!/bin/bash
# ============================================================
# DevForge Linux - Kernel Build (LFS Chapter 10)
# ============================================================
# Compiles the Linux kernel and sets up GRUB bootloader
# Run INSIDE chroot
# ============================================================

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_step()  { echo -e "\n${GREEN}========== $1 ==========${NC}\n"; }

KERNEL_VERSION="6.10.5"
MAKEFLAGS="-j$(nproc)"

cd /sources

# ============================================================
# Build Linux Kernel
# ============================================================
build_kernel() {
    log_step "Building Linux Kernel $KERNEL_VERSION"

    tar -xf "linux-${KERNEL_VERSION}.tar.xz"
    cd "linux-${KERNEL_VERSION}"

    # Clean
    make mrproper

    # Start with a default config, then customize
    make defconfig

    log_info "Enabling essential kernel features for DevForge..."

    # Enable key features via scripts/config
    scripts/config --enable CONFIG_EFI
    scripts/config --enable CONFIG_EFI_STUB
    scripts/config --enable CONFIG_IKCONFIG
    scripts/config --enable CONFIG_IKCONFIG_PROC

    # Filesystem support
    scripts/config --enable CONFIG_EXT4_FS
    scripts/config --enable CONFIG_BTRFS_FS
    scripts/config --enable CONFIG_XFS_FS
    scripts/config --enable CONFIG_VFAT_FS
    scripts/config --enable CONFIG_NTFS3_FS
    scripts/config --enable CONFIG_TMPFS

    # Networking
    scripts/config --enable CONFIG_NETFILTER
    scripts/config --enable CONFIG_BRIDGE

    # Containers & virtualization (for Docker/Podman later)
    scripts/config --enable CONFIG_NAMESPACES
    scripts/config --enable CONFIG_CGROUPS
    scripts/config --enable CONFIG_CGROUP_DEVICE
    scripts/config --enable CONFIG_CGROUP_FREEZER
    scripts/config --enable CONFIG_CGROUP_SCHED
    scripts/config --enable CONFIG_CPUSETS
    scripts/config --enable CONFIG_MEMCG
    scripts/config --enable CONFIG_VETH
    scripts/config --enable CONFIG_BRIDGE_NETFILTER
    scripts/config --enable CONFIG_OVERLAY_FS

    # USB and input
    scripts/config --enable CONFIG_USB_SUPPORT
    scripts/config --enable CONFIG_USB_XHCI_HCD
    scripts/config --enable CONFIG_USB_EHCI_HCD
    scripts/config --enable CONFIG_USB_STORAGE
    scripts/config --enable CONFIG_INPUT_EVDEV

    # Sound
    scripts/config --enable CONFIG_SOUND
    scripts/config --enable CONFIG_SND
    scripts/config --enable CONFIG_SND_HDA_INTEL

    # Graphics (needed for desktop later)
    scripts/config --enable CONFIG_DRM
    scripts/config --enable CONFIG_DRM_FBDEV_EMULATION
    scripts/config --enable CONFIG_FB
    scripts/config --enable CONFIG_FRAMEBUFFER_CONSOLE

    # Apply changes
    make olddefconfig

    # Build
    log_info "Compiling kernel (this takes a while)..."
    make $MAKEFLAGS

    # Install modules
    make modules_install

    # Install kernel
    cp -iv arch/x86/boot/bzImage /boot/vmlinuz-${KERNEL_VERSION}-devforge
    cp -iv System.map /boot/System.map-${KERNEL_VERSION}
    cp -iv .config /boot/config-${KERNEL_VERSION}

    cd /sources
    rm -rf "linux-${KERNEL_VERSION}"

    log_ok "Kernel $KERNEL_VERSION compiled and installed"
}

# ============================================================
# Setup GRUB Bootloader
# ============================================================
setup_grub() {
    log_step "Setting up GRUB Bootloader"

    log_info "NOTE: GRUB installation to disk must be done on actual"
    log_info "hardware or VM, not in WSL chroot."
    log_info "Creating GRUB config template..."

    mkdir -pv /boot/grub

    cat > /boot/grub/grub.cfg << EOF
# DevForge Linux GRUB Configuration
# Update device paths for your actual hardware

set default=0
set timeout=5

# DevForge theme
set menu_color_normal=cyan/blue
set menu_color_highlight=white/blue

menuentry "DevForge Linux $KERNEL_VERSION" {
    # UPDATE: Set root to your boot partition
    # Example: set root=(hd0,2) for /dev/sda2
    linux /boot/vmlinuz-${KERNEL_VERSION}-devforge root=/dev/sda2 ro quiet
}

menuentry "DevForge Linux $KERNEL_VERSION (Recovery)" {
    linux /boot/vmlinuz-${KERNEL_VERSION}-devforge root=/dev/sda2 ro single
}
EOF

    log_ok "GRUB config template created at /boot/grub/grub.cfg"
    log_info "When installing on VM, run:"
    log_info "  grub-install /dev/sda"
    log_info "  Then update grub.cfg with correct partition UUIDs"
}

# ============================================================
# Main
# ============================================================
build_kernel
setup_grub

log_step "Kernel & Bootloader Setup Complete!"
echo ""
log_ok "DevForge Linux base system is ready!"
echo ""
log_info "Summary of what was built:"
log_info "  - Cross-toolchain (binutils, gcc, glibc)"
log_info "  - 80+ base system packages"
log_info "  - Linux Kernel $KERNEL_VERSION"
log_info "  - GRUB bootloader config"
echo ""
log_info "To make it bootable on a VM:"
log_info "  1. Create a virtual disk and partition it"
log_info "  2. Copy the LFS filesystem to it"
log_info "  3. Install GRUB to the disk"
log_info "  4. Boot and test!"
