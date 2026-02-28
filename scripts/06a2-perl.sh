#!/bin/bash
# Perl temp build only (~8 min)
set -e
GREEN='\033[0;32m'; NC='\033[0m'
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_step() { echo -e "\n${GREEN}===== $1 =====${NC}\n"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

log_step "Perl 5.40.0 (temp)"
tar -xf perl-5.40.0.tar.xz && cd perl-5.40.0
sh Configure -des \
    -Dprefix=/usr -Dvendorprefix=/usr -Duseshrplib \
    -Dprivlib=/usr/lib/perl5/5.40/core_perl \
    -Darchlib=/usr/lib/perl5/5.40/core_perl \
    -Dsitelib=/usr/lib/perl5/5.40/site_perl \
    -Dsitearch=/usr/lib/perl5/5.40/site_perl \
    -Dvendorlib=/usr/lib/perl5/5.40/vendor_perl \
    -Dvendorarch=/usr/lib/perl5/5.40/vendor_perl
make $MAKEFLAGS
make install
cd /sources && rm -rf perl-5.40.0
echo "DONE" > /devforge/.06a2-done
log_ok "Perl temp complete"
