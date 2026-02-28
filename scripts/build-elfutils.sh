#!/bin/bash
set -e
MAKEFLAGS="-j$(nproc)"
cd /sources

echo "=== Elfutils 0.191 ==="
tar -xf elfutils-0.191.tar.bz2 && cd elfutils-0.191
./configure --prefix=/usr \
    --disable-debuginfod \
    --enable-libdebuginfod=dummy
make $MAKEFLAGS
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm -fv /usr/lib/libelf.a
cd /sources && rm -rf elfutils-0.191
echo "ELFUTILS OK"
