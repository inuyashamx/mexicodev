#!/bin/bash
# ============================================================
# DevForge Linux - Environment Setup
# ============================================================
# Sets up the LFS build environment in WSL
# Creates directory structure, user, and environment
# Must run as root: sudo bash 01-setup-env.sh
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config/distro.conf"

if [ "$(id -u)" -ne 0 ]; then
    log_error "This script must be run as root (sudo)"
    exit 1
fi

log_step "Setting up LFS Build Environment"

# --- Install host dependencies ---
log_info "Installing build dependencies..."
apt update
apt install -y \
    build-essential \
    bison \
    gawk \
    texinfo \
    python3 \
    m4 \
    wget \
    curl \
    xz-utils \
    file \
    patch \
    perl \
    sudo

# --- Create LFS directory structure ---
log_info "Creating LFS directory at $LFS..."
mkdir -pv "$LFS"
mkdir -pv "$LFS/sources"
mkdir -pv "$LFS/tools"

chmod -v a+wt "$LFS/sources"

# --- Create essential directory layout ---
log_info "Creating essential directories..."
mkdir -pv "$LFS"/{etc,var} "$LFS"/usr/{bin,lib,sbin}

for i in bin lib sbin; do
    ln -sfv usr/$i "$LFS"/$i
done

case $(uname -m) in
    x86_64) mkdir -pv "$LFS/lib64" ;;
esac

# --- Create lfs user ---
log_info "Setting up lfs build user..."
if ! id lfs &>/dev/null; then
    groupadd lfs 2>/dev/null || true
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs
    log_ok "Created user 'lfs'"
else
    log_info "User 'lfs' already exists"
fi

# Set ownership
chown -v lfs "$LFS"/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
    x86_64) chown -v lfs "$LFS/lib64" ;;
esac
chown -v lfs "$LFS/sources"

# --- Create lfs user profile ---
log_info "Configuring lfs user environment..."

cat > /home/lfs/.bash_profile << 'EOF'
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > /home/lfs/.bashrc << BASHRC_EOF
set +h
umask 022
LFS=$LFS
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=$LFS/tools/bin:/usr/bin
if [ ! -L /bin ]; then PATH=/bin:\$PATH; fi
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS="-j$(nproc)"

# DevForge build environment
PS1='[\[\033[01;33m\]DevForge-Build\[\033[00m\]] \w\$ '
echo ""
echo -e "\033[0;33m  ____             _____                    "
echo -e " |  _ \\  _____   _|  ___|__  _ __ __ _  ___ "
echo -e " | | | |/ _ \\ \\ / / |_ / _ \\| '__/ _\` |/ _ \\"
echo -e " | |_| |  __/\\ V /|  _| (_) | | | (_| |  __/"
echo -e " |____/ \\___| \\_/ |_|  \\___/|_|  \\__, |\\___|"
echo -e "                                  |___/       \033[0m"
echo ""
echo -e " Build Environment | LFS $LFS | $(nproc) cores"
echo ""
BASHRC_EOF

chown lfs:lfs /home/lfs/.bash_profile
chown lfs:lfs /home/lfs/.bashrc

# --- Summary ---
echo ""
log_step "Environment Setup Complete"
log_ok "LFS directory: $LFS"
log_ok "Sources dir:   $LFS/sources"
log_ok "Tools dir:     $LFS/tools"
log_ok "Build user:    lfs"
echo ""
log_info "Next steps:"
echo "  1. Run: bash 02-download-sources.sh"
echo "  2. Then switch to lfs user: su - lfs"
echo "  3. Run the toolchain build scripts"
