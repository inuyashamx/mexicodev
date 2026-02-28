#!/bin/bash
# MexicoDev Linux - Strip and Package
# WARNING: Run this from OUTSIDE the chroot to avoid corrupting running libraries
# Usage: sudo bash scripts/09-package.sh
set -e

LFS=/mnt/lfs

echo "=== Stripping binaries (from outside chroot) ==="

# Strip static libraries
find $LFS/usr/lib -type f -name '*.a' -exec strip --strip-debug {} \; 2>/dev/null || true

# Strip shared libraries - EXCLUDE critical glibc files
find $LFS/usr/lib -type f -name '*.so*' \
    ! -name 'ld-linux*' \
    ! -name 'libc.so*' \
    ! -name 'libc-*.so' \
    ! -name 'libpthread*' \
    ! -name 'libdl*' \
    -exec strip --strip-unneeded {} \; 2>/dev/null || true

# Strip binaries
find $LFS/usr/bin $LFS/usr/sbin $LFS/usr/libexec \
    $LFS/sbin $LFS/bin \
    -type f -executable \
    -exec strip --strip-all {} \; 2>/dev/null || true

echo "=== Cleaning up ==="
rm -rf $LFS/sources/*
rm -rf $LFS/tmp/*

echo "=== Creating release tarball ==="
cd $LFS
tar cJpf /tmp/mexicodev-0.1.0-x86_64.tar.xz \
    --exclude='./proc/*' \
    --exclude='./sys/*' \
    --exclude='./dev/*' \
    --exclude='./run/*' \
    --exclude='./tmp/*' \
    --exclude='./sources/*' \
    .

echo "=== Size ==="
du -sh $LFS/usr $LFS/boot $LFS/etc 2>/dev/null || true
ls -lh /tmp/mexicodev-0.1.0-x86_64.tar.xz
echo "PACKAGE DONE"
