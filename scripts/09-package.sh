#!/bin/bash
# Strip binaries and create release tarball
set -e
echo "=== Stripping binaries ==="

# Strip debug symbols from libraries and binaries
find /usr/lib -type f -name \*.a -exec strip --strip-debug {} \; 2>/dev/null || true
find /usr/lib -type f -name \*.so* -exec strip --strip-unneeded {} \; 2>/dev/null || true
find /usr/{bin,sbin,libexec} -type f -exec strip --strip-all {} \; 2>/dev/null || true

echo "=== Cleaning up ==="
rm -rf /sources/*
rm -rf /devforge
rm -rf /tmp/*

echo "=== Size after strip ==="
du -sh /usr /boot /etc /var /lib 2>/dev/null || true
echo "STRIP DONE"
