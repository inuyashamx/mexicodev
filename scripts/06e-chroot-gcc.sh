#!/bin/bash
# Phase E: GCC final build inside chroot
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_step()  { echo -e "\n${GREEN}========== $1 ==========${NC}\n"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

log_step "Building GCC 14.2.0 (final)"
tar -xf gcc-14.2.0.tar.xz && cd gcc-14.2.0

case $(uname -m) in
    x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;;
esac

mkdir -v build && cd build
../configure \
    --prefix=/usr \
    LD=ld \
    --enable-languages=c,c++ \
    --enable-default-pie \
    --enable-default-ssp \
    --enable-host-pie \
    --disable-multilib \
    --disable-bootstrap \
    --disable-fixincludes \
    --with-system-zlib

make $MAKEFLAGS
make install

ln -svr /usr/bin/gcc /usr/bin/cc
mkdir -pv /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

# Sanity check
log_info "GCC sanity check..."
echo 'int main(){}' > /tmp/dummy.c
cc /tmp/dummy.c -v -Wl,--verbose &> /tmp/dummy.log
readelf -l /tmp/a.out | grep ': /lib' && log_ok "GCC sanity check PASSED"
rm -v /tmp/dummy.c /tmp/a.out /tmp/dummy.log

cd /sources && rm -rf gcc-14.2.0
log_ok "GCC final complete"
echo "PHASE_E_DONE" > /devforge/.phase-e-done
