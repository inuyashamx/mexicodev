#!/bin/bash
set -e
MAKEFLAGS="-j$(nproc)"
cd /sources

echo "=== Man-DB 2.12.1 ==="
tar -xf man-db-2.12.1.tar.xz && cd man-db-2.12.1
./configure --prefix=/usr --sysconfdir=/etc --disable-setuid \
    --enable-cache-owner=bin --with-browser=/usr/bin/lynx \
    --with-vgrind=/usr/bin/vgrind --with-grap=/usr/bin/grap
make $MAKEFLAGS && make install
cd /sources && rm -rf man-db-2.12.1
echo "Man-DB OK"

echo "=== Vim 9.1.0660 ==="
tar -xf vim-9.1.0660.tar.gz && cd vim-9.1.0660
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make $MAKEFLAGS && make install
ln -sfv vim /usr/bin/vi
cd /sources && rm -rf vim-9.1.0660
echo "Vim OK"

echo "DONE" > /devforge/.phase-d-done
echo "PHASE D COMPLETE"
