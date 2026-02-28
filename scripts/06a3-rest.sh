#!/bin/bash
# Python + Texinfo + Util-linux + cleanup (~5 min)
set -e
GREEN='\033[0;32m'; NC='\033[0m'
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_step() { echo -e "\n${GREEN}===== $1 =====${NC}\n"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

log_step "Python 3.12.5 (temp)"
tar -xf Python-3.12.5.tar.xz && cd Python-3.12.5
./configure --prefix=/usr --without-ensurepip
make $MAKEFLAGS && make install
cd /sources && rm -rf Python-3.12.5
log_ok "Python done"

log_step "Texinfo 7.1.1 (temp)"
tar -xf texinfo-7.1.1.tar.xz && cd texinfo-7.1.1
./configure --prefix=/usr
make $MAKEFLAGS && make install
cd /sources && rm -rf texinfo-7.1.1
log_ok "Texinfo done"

log_step "Util-linux 2.40.2 (temp)"
tar -xf util-linux-2.40.2.tar.xz && cd util-linux-2.40.2
mkdir -pv /var/lib/hwclock
./configure --libdir=/usr/lib --runstatedir=/run \
    --disable-chfn-chsh --disable-login --disable-nologin \
    --disable-su --disable-setpriv --disable-runuser \
    --disable-pylibmount --disable-static --disable-liblastlog2 \
    --without-python ADJTIME_PATH=/var/lib/hwclock/adjtime \
    --docdir=/usr/share/doc/util-linux-2.40.2
make $MAKEFLAGS && make install
cd /sources && rm -rf util-linux-2.40.2
log_ok "Util-linux done"

log_step "Cleanup"
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete 2>/dev/null || true
rm -rf /tools
echo "DONE" > /devforge/.06a3-done
log_ok "Phase A3 complete - all temp tools done"
