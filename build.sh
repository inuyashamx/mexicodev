#!/bin/bash
# ============================================================
#   ____             _____
#  |  _ \  _____   _|  ___|__  _ __ __ _  ___
#  | | | |/ _ \ \ / / |_ / _ \| '__/ _` |/ _ \
#  | |_| |  __/\ V /|  _| (_) | | | (_| |  __/
#  |____/ \___| \_/ |_|  \___/|_|  \__, |\___|
#                                   |___/
#  DevForge Linux - Master Build Script
#  A developer-focused Linux distro built from scratch
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/config/distro.conf"

show_help() {
    echo ""
    echo "  DevForge Linux Build System"
    echo "  ==========================="
    echo ""
    echo "  Usage: bash build.sh <command>"
    echo ""
    echo "  Commands:"
    echo "    check       - Verify host system requirements"
    echo "    setup       - Set up build environment (requires root)"
    echo "    download    - Download all source packages"
    echo "    toolchain   - Build cross-toolchain (as lfs user)"
    echo "    crosstools  - Cross-compile temporary tools (as lfs user)"
    echo "    chroot      - Enter chroot environment (requires root)"
    echo "    all         - Run full build sequence"
    echo "    status      - Show build progress"
    echo "    clean       - Clean build directory"
    echo ""
    echo "  Build Order:"
    echo "    1. bash build.sh check"
    echo "    2. sudo bash build.sh setup"
    echo "    3. bash build.sh download"
    echo "    4. su - lfs -c 'bash $SCRIPT_DIR/build.sh toolchain'"
    echo "    5. su - lfs -c 'bash $SCRIPT_DIR/build.sh crosstools'"
    echo "    6. sudo bash build.sh chroot"
    echo "    7. (inside chroot) bash /devforge/06-base-system.sh"
    echo "    8. (inside chroot) bash /devforge/07-system-config.sh"
    echo "    9. (inside chroot) bash /devforge/08-kernel.sh"
    echo ""
}

cmd_check() {
    bash "$SCRIPT_DIR/scripts/00-check-host.sh"
}

cmd_setup() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Setup requires root: sudo bash build.sh setup"
        exit 1
    fi
    bash "$SCRIPT_DIR/scripts/01-setup-env.sh"
}

cmd_download() {
    bash "$SCRIPT_DIR/scripts/02-download-sources.sh"
}

cmd_toolchain() {
    bash "$SCRIPT_DIR/scripts/03-toolchain.sh"
}

cmd_crosstools() {
    bash "$SCRIPT_DIR/scripts/04-cross-tools.sh"
}

cmd_chroot() {
    if [ "$(id -u)" -ne 0 ]; then
        log_error "Chroot requires root: sudo bash build.sh chroot"
        exit 1
    fi
    bash "$SCRIPT_DIR/scripts/05-chroot.sh"
}

cmd_status() {
    echo ""
    log_step "DevForge Linux - Build Status"

    check_step() {
        local name="$1"
        local check="$2"
        if eval "$check" 2>/dev/null; then
            log_ok "$name"
        else
            log_info "$name (pending)"
        fi
    }

    check_step "1. Host check"         "[ -f $LFS/sources/.host-checked ]"
    check_step "2. Environment setup"  "[ -d $LFS/tools ]"
    check_step "3. Sources downloaded" "[ -f $LFS/sources/binutils-${BINUTILS_VERSION}.tar.xz ]"
    check_step "4. Cross-toolchain"    "[ -f $LFS/tools/bin/${LFS_TGT}-gcc ]"
    check_step "5. Cross temp tools"   "[ -f $LFS/usr/bin/bash ]"
    check_step "6. Chroot ready"       "[ -f $LFS/etc/passwd ]"
    check_step "7. Base system"        "[ -f $LFS/usr/bin/gcc ]"
    check_step "8. System configured"  "[ -f $LFS/etc/os-release ]"
    check_step "9. Kernel built"       "ls $LFS/boot/vmlinuz-* 2>/dev/null"

    echo ""
}

cmd_clean() {
    log_warn "This will delete the entire LFS build at $LFS"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        sudo rm -rf "$LFS"
        log_ok "Build directory cleaned"
    else
        log_info "Cancelled"
    fi
}

# ============================================================
# Main
# ============================================================
case "${1:-help}" in
    check)      cmd_check ;;
    setup)      cmd_setup ;;
    download)   cmd_download ;;
    toolchain)  cmd_toolchain ;;
    crosstools) cmd_crosstools ;;
    chroot)     cmd_chroot ;;
    status)     cmd_status ;;
    clean)      cmd_clean ;;
    help|*)     show_help ;;
esac
