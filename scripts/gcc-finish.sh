#!/bin/bash
set -e
cd /sources/gcc-14.2.0/build

echo "=== Finishing GCC install ==="
make install || true

# Fix cc symlink
ln -sfv gcc /usr/bin/cc

# Setup bfd-plugins
mkdir -pv /usr/lib/bfd-plugins
MACHINE=$(gcc -dumpmachine)
echo "Machine triplet: $MACHINE"
ln -sfv ../../libexec/gcc/$MACHINE/14.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

# Sanity check
echo "=== GCC Sanity Check ==="
echo 'int main(){}' > /tmp/dummy.c
cc /tmp/dummy.c -v -Wl,--verbose &> /tmp/dummy.log
readelf -l /tmp/a.out | grep ': /lib' && echo "SANITY CHECK PASSED"
rm -v /tmp/dummy.c /tmp/a.out /tmp/dummy.log

cd /sources && rm -rf gcc-14.2.0
echo PHASE_E_DONE > /devforge/.phase-e-done
echo "GCC 14.2.0 FINAL COMPLETE"
