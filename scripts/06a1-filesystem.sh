#!/bin/bash
# Filesystem layout + Gettext + Bison (fast, ~3 min)
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_step() { echo -e "\n${GREEN}===== $1 =====${NC}\n"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

log_step "Filesystem Layout"
mkdir -pv /{boot,home,mnt,opt,srv} 2>/dev/null || true
mkdir -pv /etc/{opt,sysconfig} 2>/dev/null || true
mkdir -pv /lib/firmware 2>/dev/null || true
mkdir -pv /media/{floppy,cdrom} 2>/dev/null || true
mkdir -pv /usr/{,local/}{include,src} 2>/dev/null || true
mkdir -pv /usr/local/{bin,lib,sbin} 2>/dev/null || true
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man} 2>/dev/null || true
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo} 2>/dev/null || true
mkdir -pv /usr/{,local/}share/man/man{1..8} 2>/dev/null || true
mkdir -pv /var/{cache,local,log,mail,opt,spool} 2>/dev/null || true
mkdir -pv /var/lib/{color,misc,locate} 2>/dev/null || true
ln -sfv /run /var/run 2>/dev/null || true
ln -sfv /run/lock /var/lock 2>/dev/null || true
install -dv -m 0750 /root 2>/dev/null || true
install -dv -m 1777 /tmp /var/tmp 2>/dev/null || true
ln -sv /proc/self/mounts /etc/mtab 2>/dev/null || true
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
log_ok "Filesystem done"

log_step "Gettext 0.22.5"
tar -xf gettext-0.22.5.tar.xz && cd gettext-0.22.5
./configure --disable-shared
make $MAKEFLAGS
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
cd /sources && rm -rf gettext-0.22.5
log_ok "Gettext done"

log_step "Bison 3.8.2"
tar -xf bison-3.8.2.tar.xz && cd bison-3.8.2
./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2
make $MAKEFLAGS && make install
cd /sources && rm -rf bison-3.8.2
log_ok "Bison done"

echo "DONE" > /devforge/.06a1-done
log_ok "Phase A1 complete"
