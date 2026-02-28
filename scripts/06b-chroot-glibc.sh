#!/bin/bash
# Phase B: Glibc final build inside chroot
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_step()  { echo -e "\n${GREEN}========== $1 ==========${NC}\n"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

log_step "Building Glibc 2.40 (final)"
tar -xf glibc-2.40.tar.xz && cd glibc-2.40

patch -Np1 -i ../glibc-2.40-fhs-1.patch
mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms

../configure \
    --prefix=/usr \
    --disable-werror \
    --enable-kernel=4.19 \
    --enable-stack-protector=strong \
    --disable-nscd \
    libc_cv_slibdir=/usr/lib

make $MAKEFLAGS
make install

sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

# Locales
mkdir -pv /usr/lib/locale
localedef -i C -f UTF-8 C.UTF-8
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f UTF-8 es_MX.UTF-8

# nsswitch
cat > /etc/nsswitch.conf << "EOF"
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
EOF

# Timezone
if [ -f /usr/share/zoneinfo/America/Mexico_City ]; then
    cp -v /usr/share/zoneinfo/America/Mexico_City /etc/localtime
fi

# ld.so.conf
cat > /etc/ld.so.conf << "EOF"
/usr/local/lib
/opt/lib
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -pv /etc/ld.so.conf.d

cd /sources && rm -rf glibc-2.40
log_ok "Glibc final complete"
echo "PHASE_B_DONE" > /devforge/.phase-b-done
