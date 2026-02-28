#!/bin/bash
# Phase D: Build Chapter 8 packages (second batch + system tools)
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_step()  { echo -e "\n${GREEN}========== $1 ==========${NC}\n"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

bp() {
    local name="$1" tarball="$2" configure_args="$3"
    log_step "Building $name"
    local dir="${tarball%.tar.*}"
    tar -xf "$tarball" && cd "$dir"
    if [ -f configure ]; then
        ./configure --prefix=/usr $configure_args
        make $MAKEFLAGS
        make install
    fi
    cd /sources && rm -rf "$dir"
    log_ok "$name done"
}

bp "Autoconf 2.72" "autoconf-2.72.tar.xz" ""
bp "Automake 1.17" "automake-1.17.tar.xz" "--docdir=/usr/share/doc/automake-1.17"

# OpenSSL (custom)
log_step "OpenSSL 3.3.1"
tar -xf openssl-3.3.1.tar.gz && cd openssl-3.3.1
./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
make $MAKEFLAGS
make MANSUFFIX=ssl install
cd /sources && rm -rf openssl-3.3.1

# Ncurses (final)
log_step "Ncurses 6.5 (final)"
tar -xf ncurses-6.5.tar.gz && cd ncurses-6.5
./configure --prefix=/usr --mandir=/usr/share/man --with-shared \
    --without-debug --without-normal --with-cxx-shared \
    --enable-pc-files --with-pkg-config-libdir=/usr/lib/pkgconfig
make $MAKEFLAGS && make DESTDIR="" install
ln -sfv libncursesw.so /usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i /usr/include/curses.h
cd /sources && rm -rf ncurses-6.5

bp "Libffi 3.4.6" "libffi-3.4.6.tar.gz" "--disable-static --with-gcc-arch=native"

# Python (final)
log_step "Python 3.12.5 (final)"
tar -xf Python-3.12.5.tar.xz && cd Python-3.12.5
./configure --prefix=/usr --enable-shared --with-system-expat
make $MAKEFLAGS
make install
ln -sfv python3 /usr/bin/python 2>/dev/null || true
cd /sources && rm -rf Python-3.12.5

bp "Libpipeline 1.5.7" "libpipeline-1.5.7.tar.gz" ""
bp "Make 4.4.1" "make-4.4.1.tar.gz" ""
bp "Patch 2.7.6" "patch-2.7.6.tar.xz" ""
bp "Tar 1.35" "tar-1.35.tar.xz" "--docdir=/usr/share/doc/tar-1.35"
bp "Less 661" "less-661.tar.gz" "--sysconfdir=/etc"
bp "Gzip 1.13" "gzip-1.13.tar.xz" ""
bp "Diffutils 3.10" "diffutils-3.10.tar.xz" ""
bp "Findutils 4.10.0" "findutils-4.10.0.tar.xz" "--localstatedir=/var/lib/locate"
bp "Gawk 5.3.1" "gawk-5.3.1.tar.xz" "--docdir=/usr/share/doc/gawk-5.3.1"
bp "Libtool 2.4.7" "libtool-2.4.7.tar.xz" ""
bp "Inetutils 2.5" "inetutils-2.5.tar.xz" "--bindir=/usr/bin --localstatedir=/var --disable-logger --disable-whois --disable-rcp --disable-rexec --disable-rlogin --disable-rsh --disable-servers"

# Perl (final)
log_step "Perl 5.40.0 (final)"
tar -xf perl-5.40.0.tar.xz && cd perl-5.40.0
sh Configure -des \
    -Dprefix=/usr -Dvendorprefix=/usr -Duseshrplib -Dusethreads \
    -Dprivlib=/usr/lib/perl5/5.40/core_perl \
    -Darchlib=/usr/lib/perl5/5.40/core_perl \
    -Dsitelib=/usr/lib/perl5/5.40/site_perl \
    -Dsitearch=/usr/lib/perl5/5.40/site_perl \
    -Dvendorlib=/usr/lib/perl5/5.40/vendor_perl \
    -Dvendorarch=/usr/lib/perl5/5.40/vendor_perl \
    -Accflags='-DNO_LOCALE'
make -j1
make install
cd /sources && rm -rf perl-5.40.0

bp "Texinfo 7.1.1" "texinfo-7.1.1.tar.xz" ""
bp "Man-DB 2.12.1" "man-db-2.12.1.tar.xz" "--docdir=/usr/share/doc/man-db-2.12.1 --sysconfdir=/etc --disable-setuid --enable-cache-owner=bin --with-browser=/usr/bin/lynx --with-vgrind=/usr/bin/vgrind --with-grap=/usr/bin/grap"

# Bash (final)
log_step "Bash 5.2.32 (final)"
tar -xf bash-5.2.32.tar.gz && cd bash-5.2.32
./configure --prefix=/usr --without-bash-malloc --with-installed-readline \
    --docdir=/usr/share/doc/bash-5.2.32 bash_cv_strtold_broken=no
make $MAKEFLAGS
make install
cd /sources && rm -rf bash-5.2.32

# Coreutils (final)
log_step "Coreutils 9.5 (final)"
tar -xf coreutils-9.5.tar.xz && cd coreutils-9.5
patch -Np1 -i ../coreutils-9.5-i18n-2.patch
./configure --prefix=/usr --enable-no-install-program=kill,uptime
make $MAKEFLAGS
make install
mv -v /usr/bin/chroot /usr/sbin 2>/dev/null || true
cd /sources && rm -rf coreutils-9.5

# Vim
log_step "Vim 9.1.0660"
tar -xf vim-9.1.0660.tar.gz && cd vim-9.1.0660
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
./configure --prefix=/usr
make $MAKEFLAGS
make install
ln -sfv vim /usr/bin/vi
cd /sources && rm -rf vim-9.1.0660

log_ok "Phase D complete"
echo "PHASE_D_DONE" > /devforge/.phase-d-done
