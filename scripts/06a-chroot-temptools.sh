#!/bin/bash
# Phase A: Filesystem + Temporary tools inside chroot
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_step()  { echo -e "\n${GREEN}========== $1 ==========${NC}\n"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

extract_and_cd() { tar -xf "$1" && cd "${1%.tar.*}"; }
cleanup() { cd /sources && rm -rf "$1" && log_ok "Cleaned $1"; }

# --- Filesystem layout ---
log_step "Creating Filesystem Layout"
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
ln -sv /proc/self/mounts /etc/mtab 2>/dev/null || true

cat > /etc/hosts << EOF
127.0.0.1  localhost devforge
::1        localhost
EOF

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Nobody:/dev/null:/usr/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664 /var/log/lastlog
chmod -v 600 /var/log/btmp
log_ok "Filesystem layout done"

# --- Gettext (temp) ---
log_step "Gettext 0.22.5 (temp)"
extract_and_cd gettext-0.22.5.tar.xz
./configure --disable-shared
make $MAKEFLAGS
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cleanup gettext-0.22.5

# --- Bison (temp) ---
log_step "Bison 3.8.2 (temp)"
extract_and_cd bison-3.8.2.tar.xz
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make $MAKEFLAGS
make install
cleanup bison-3.8.2

# --- Perl (temp) ---
log_step "Perl 5.40.0 (temp)"
extract_and_cd perl-5.40.0.tar.xz
sh Configure -des \
    -Dprefix=/usr \
    -Dvendorprefix=/usr \
    -Duseshrplib \
    -Dprivlib=/usr/lib/perl5/5.40/core_perl \
    -Darchlib=/usr/lib/perl5/5.40/core_perl \
    -Dsitelib=/usr/lib/perl5/5.40/site_perl \
    -Dsitearch=/usr/lib/perl5/5.40/site_perl \
    -Dvendorlib=/usr/lib/perl5/5.40/vendor_perl \
    -Dvendorarch=/usr/lib/perl5/5.40/vendor_perl
make $MAKEFLAGS
make install
cleanup perl-5.40.0

# --- Python (temp) ---
log_step "Python 3.12.5 (temp)"
extract_and_cd Python-3.12.5.tar.xz
./configure --prefix=/usr --without-ensurepip
make $MAKEFLAGS
make install
cleanup Python-3.12.5

# --- Texinfo (temp) ---
log_step "Texinfo 7.1.1 (temp)"
extract_and_cd texinfo-7.1.1.tar.xz
./configure --prefix=/usr
make $MAKEFLAGS
make install
cleanup texinfo-7.1.1

# --- Util-linux (temp) ---
log_step "Util-linux 2.40.2 (temp)"
extract_and_cd util-linux-2.40.2.tar.xz
mkdir -pv /var/lib/hwclock
./configure \
    --libdir=/usr/lib \
    --runstatedir=/run \
    --disable-chfn-chsh --disable-login --disable-nologin \
    --disable-su --disable-setpriv --disable-runuser \
    --disable-pylibmount --disable-static --disable-liblastlog2 \
    --without-python \
    ADJTIME_PATH=/var/lib/hwclock/adjtime \
    --docdir=/usr/share/doc/util-linux-2.40.2
make $MAKEFLAGS
make install
cleanup util-linux-2.40.2

# --- Cleanup temp ---
log_step "Cleaning temporary system"
rm -rf /usr/share/{info,man,doc}/*
find /usr/{lib,libexec} -name \*.la -delete 2>/dev/null || true
rm -rf /tools

log_ok "Phase A complete - temp tools done"
echo "PHASE_A_DONE" > /devforge/.phase-a-done
