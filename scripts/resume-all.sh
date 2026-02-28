#!/bin/bash
# DevForge Linux - Resume build from Phase B onwards
# Run inside chroot: bash /devforge/resume-all.sh
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
log_ok()   { echo -e "${GREEN}[OK]${NC} $1"; }
log_step() { echo -e "\n${GREEN}========== $1 ==========${NC}\n"; }
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
MAKEFLAGS="-j$(nproc)"
cd /sources

# Helper: build a standard autoconf package
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

# Helper: skip if marker exists
phase_done() { [ -f "/devforge/.$1-done" ]; }
mark_done()  { echo "DONE" > "/devforge/.$1-done"; }

########################################
# PHASE B: Glibc final
########################################
if ! phase_done "phase-b"; then
    log_step "PHASE B: Glibc 2.40 (final)"
    tar -xf glibc-2.40.tar.xz && cd glibc-2.40
    patch -Np1 -i ../glibc-2.40-fhs-1.patch
    mkdir -v build && cd build
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure \
        --prefix=/usr \
        --disable-werror \
        --enable-kernel=4.19 \
        --enable-stack-protector=strong \
        --disable-nscd \
        libc_cv_slibdir=/usr/lib
    make $MAKEFLAGS
    make install
    sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
    mkdir -pv /usr/lib/locale
    localedef -i C -f UTF-8 C.UTF-8
    localedef -i en_US -f UTF-8 en_US.UTF-8
    localedef -i es_MX -f UTF-8 es_MX.UTF-8
    cat > /etc/nsswitch.conf << "EOF"
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
EOF
    cat > /etc/ld.so.conf << "EOF"
/usr/local/lib
/opt/lib
include /etc/ld.so.conf.d/*.conf
EOF
    mkdir -pv /etc/ld.so.conf.d
    cd /sources && rm -rf glibc-2.40
    mark_done "phase-b"
    log_ok "PHASE B complete - Glibc final installed"
else
    log_info "Phase B already done, skipping"
fi

########################################
# PHASE C remainder: Core packages
########################################
if ! phase_done "phase-c"; then
    log_step "PHASE C: Core packages"

    # Skip already installed from partial run
    if [ ! -f /usr/lib/libz.so ]; then
        log_step "Zlib 1.3.1"
        tar -xf zlib-1.3.1.tar.gz && cd zlib-1.3.1
        ./configure --prefix=/usr
        make $MAKEFLAGS && make install
        rm -fv /usr/lib/libz.a
        cd /sources && rm -rf zlib-1.3.1
    else log_info "Zlib already installed, skipping"; fi

    if [ ! -f /usr/lib/libbz2.so ]; then
        log_step "Bzip2 1.0.8"
        tar -xf bzip2-1.0.8.tar.gz && cd bzip2-1.0.8
        patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
        sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
        sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
        make -f Makefile-libbz2_so && make clean
        make $MAKEFLAGS
        make PREFIX=/usr install
        cp -av libbz2.so.* /usr/lib
        ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so
        cp -v bzip2-shared /usr/bin/bzip2
        for i in bunzip2 bzcat; do ln -sfv bzip2 /usr/bin/$i; done
        rm -fv /usr/lib/libbz2.a
        cd /sources && rm -rf bzip2-1.0.8
    else log_info "Bzip2 already installed, skipping"; fi

    if [ ! -f /usr/lib/liblzma.so ]; then
        bp "Xz 5.6.2" "xz-5.6.2.tar.xz" "--disable-static --docdir=/usr/share/doc/xz-5.6.2"
    else log_info "Xz already installed, skipping"; fi

    if [ ! -f /usr/lib/libzstd.so ]; then
        log_step "Zstd 1.5.6"
        tar -xf zstd-1.5.6.tar.gz && cd zstd-1.5.6
        make prefix=/usr $MAKEFLAGS
        make prefix=/usr install
        rm -v /usr/lib/libzstd.a
        cd /sources && rm -rf zstd-1.5.6
    else log_info "Zstd already installed, skipping"; fi

    if [ ! -f /usr/lib/libmagic.so ]; then
        bp "File 5.45" "file-5.45.tar.gz" ""
    else log_info "File already installed, skipping"; fi

    if [ ! -f /usr/lib/libreadline.so ]; then
        bp "Readline 8.2.13" "readline-8.2.13.tar.gz" "--disable-static --with-curses --docdir=/usr/share/doc/readline-8.2.13"
    else log_info "Readline already installed, skipping"; fi

    bp "M4 1.4.19" "m4-1.4.19.tar.xz" ""

    if [ ! -f /usr/bin/bc ]; then
        bp "Bc 7.0.3" "bc-7.0.3.tar.xz" ""
    else log_info "Bc already installed, skipping"; fi

    bp "Flex 2.6.4" "flex-2.6.4.tar.gz" "--docdir=/usr/share/doc/flex-2.6.4 --disable-static"

    # Binutils final
    log_step "Binutils 2.43.1 (final)"
    tar -xf binutils-2.43.1.tar.xz && cd binutils-2.43.1
    mkdir build && cd build
    ../configure --prefix=/usr --sysconfdir=/etc --enable-gold --enable-ld=default \
        --enable-plugins --enable-shared --disable-werror --enable-64-bit-bfd \
        --enable-new-dtags --enable-default-hash-style=gnu
    make tooldir=/usr $MAKEFLAGS
    make tooldir=/usr install
    rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
    cd /sources && rm -rf binutils-2.43.1

    bp "GMP 6.3.0" "gmp-6.3.0.tar.xz" "--enable-cxx --disable-static --docdir=/usr/share/doc/gmp-6.3.0"
    bp "MPFR 4.2.1" "mpfr-4.2.1.tar.xz" "--disable-static --enable-thread-safe --docdir=/usr/share/doc/mpfr-4.2.1"
    bp "MPC 1.3.1" "mpc-1.3.1.tar.gz" "--disable-static --docdir=/usr/share/doc/mpc-1.3.1"
    bp "Attr 2.5.2" "attr-2.5.2.tar.gz" "--disable-static --sysconfdir=/etc --docdir=/usr/share/doc/attr-2.5.2"
    bp "Acl 2.3.2" "acl-2.3.2.tar.xz" "--disable-static --docdir=/usr/share/doc/acl-2.3.2"

    log_step "Libcap 2.70"
    tar -xf libcap-2.70.tar.xz && cd libcap-2.70
    sed -i '/install -m.*STA/d' libcap/Makefile
    make prefix=/usr lib=lib $MAKEFLAGS
    make prefix=/usr lib=lib install
    cd /sources && rm -rf libcap-2.70

    bp "Libxcrypt 4.4.36" "libxcrypt-4.4.36.tar.xz" "--enable-hashes=strong,glibc --enable-obsolete-api=no --disable-static --disable-failure-tokens"
    bp "Sed 4.9" "sed-4.9.tar.xz" ""
    bp "Psmisc 23.7" "psmisc-23.7.tar.xz" ""
    bp "Gettext 0.22.5" "gettext-0.22.5.tar.xz" "--disable-static --docdir=/usr/share/doc/gettext-0.22.5"
    bp "Bison 3.8.2" "bison-3.8.2.tar.xz" "--docdir=/usr/share/doc/bison-3.8.2"
    bp "Grep 3.11" "grep-3.11.tar.xz" ""
    bp "GDBM 1.24" "gdbm-1.24.tar.gz" "--disable-static --enable-libgdbm-compat"
    bp "Gperf 3.1" "gperf-3.1.tar.gz" "--docdir=/usr/share/doc/gperf-3.1"
    bp "Expat 2.6.2" "expat-2.6.2.tar.xz" "--disable-static --docdir=/usr/share/doc/expat-2.6.2"

    mark_done "phase-c"
    log_ok "PHASE C complete"
else
    log_info "Phase C already done, skipping"
fi

########################################
# PHASE D: Second batch + system tools
########################################
if ! phase_done "phase-d"; then
    log_step "PHASE D: System packages"

    bp "Autoconf 2.72" "autoconf-2.72.tar.xz" ""
    bp "Automake 1.17" "automake-1.17.tar.xz" "--docdir=/usr/share/doc/automake-1.17"

    log_step "OpenSSL 3.3.1"
    tar -xf openssl-3.3.1.tar.gz && cd openssl-3.3.1
    ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
    make $MAKEFLAGS
    make MANSUFFIX=ssl install
    cd /sources && rm -rf openssl-3.3.1

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

    # Perl final (with locale fix)
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

    log_step "Bash 5.2.32 (final)"
    tar -xf bash-5.2.32.tar.gz && cd bash-5.2.32
    ./configure --prefix=/usr --without-bash-malloc --with-installed-readline \
        --docdir=/usr/share/doc/bash-5.2.32 bash_cv_strtold_broken=no
    make $MAKEFLAGS
    make install
    cd /sources && rm -rf bash-5.2.32

    log_step "Coreutils 9.5 (final)"
    tar -xf coreutils-9.5.tar.xz && cd coreutils-9.5
    patch -Np1 -i ../coreutils-9.5-i18n-2.patch
    ./configure --prefix=/usr --enable-no-install-program=kill,uptime
    make $MAKEFLAGS
    make install
    mv -v /usr/bin/chroot /usr/sbin 2>/dev/null || true
    cd /sources && rm -rf coreutils-9.5

    log_step "Vim 9.1.0660"
    tar -xf vim-9.1.0660.tar.gz && cd vim-9.1.0660
    echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    ln -sfv vim /usr/bin/vi
    cd /sources && rm -rf vim-9.1.0660

    mark_done "phase-d"
    log_ok "PHASE D complete"
else
    log_info "Phase D already done, skipping"
fi

########################################
# PHASE E: GCC final
########################################
if ! phase_done "phase-e"; then
    log_step "PHASE E: GCC 14.2.0 (final)"
    tar -xf gcc-14.2.0.tar.xz && cd gcc-14.2.0

    case $(uname -m) in
        x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;;
    esac

    mkdir -v build && cd build
    ../configure \
        --prefix=/usr \
        LD=ld \
        --enable-languages=c,c++ \
        --enable-default-pie \
        --enable-default-ssp \
        --enable-host-pie \
        --disable-multilib \
        --disable-bootstrap \
        --disable-fixincludes \
        --with-system-zlib
    make $MAKEFLAGS
    make install

    ln -svr /usr/bin/gcc /usr/bin/cc
    mkdir -pv /usr/lib/bfd-plugins
    ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so /usr/lib/bfd-plugins/

    # Sanity check
    log_info "GCC sanity check..."
    echo 'int main(){}' > /tmp/dummy.c
    cc /tmp/dummy.c -v -Wl,--verbose &> /tmp/dummy.log
    readelf -l /tmp/a.out | grep ': /lib' && log_ok "GCC sanity check PASSED"
    rm -v /tmp/dummy.c /tmp/a.out /tmp/dummy.log

    cd /sources && rm -rf gcc-14.2.0
    mark_done "phase-e"
    log_ok "PHASE E complete - GCC final installed"
else
    log_info "Phase E already done, skipping"
fi

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ALL BUILD PHASES COMPLETE!${NC}"
echo -e "${GREEN}  DevForge Linux base system is ready.${NC}"
echo -e "${GREEN}============================================${NC}"
