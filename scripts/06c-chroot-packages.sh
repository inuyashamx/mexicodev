#!/bin/bash
# Phase C: Build Chapter 8 packages (core system)
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

# Zlib
log_step "Zlib 1.3.1"
tar -xf zlib-1.3.1.tar.gz && cd zlib-1.3.1
./configure --prefix=/usr
make $MAKEFLAGS && make install
rm -fv /usr/lib/libz.a
cd /sources && rm -rf zlib-1.3.1

# Bzip2 (custom build)
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

# Xz
bp "Xz 5.6.2" "xz-5.6.2.tar.xz" "--disable-static --docdir=/usr/share/doc/xz-5.6.2"

# Zstd (custom)
log_step "Zstd 1.5.6"
tar -xf zstd-1.5.6.tar.gz && cd zstd-1.5.6
make prefix=/usr $MAKEFLAGS
make prefix=/usr install
rm -v /usr/lib/libzstd.a
cd /sources && rm -rf zstd-1.5.6

bp "File 5.45" "file-5.45.tar.gz" ""
bp "Readline 8.2.13" "readline-8.2.13.tar.gz" "--disable-static --with-curses --docdir=/usr/share/doc/readline-8.2.13"
bp "M4 1.4.19" "m4-1.4.19.tar.xz" ""
bp "Bc 7.0.3" "bc-7.0.3.tar.xz" ""
bp "Flex 2.6.4" "flex-2.6.4.tar.gz" "--docdir=/usr/share/doc/flex-2.6.4 --disable-static"

# Binutils (final)
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

# Libcap (custom)
log_step "Libcap 2.70"
tar -xf libcap-2.70.tar.xz && cd libcap-2.70
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib $MAKEFLAGS
make prefix=/usr lib=lib install
cd /sources && rm -rf libcap-2.70

# Libxcrypt
bp "Libxcrypt 4.4.36" "libxcrypt-4.4.36.tar.xz" "--enable-hashes=strong,glibc --enable-obsolete-api=no --disable-static --disable-failure-tokens"

bp "Sed 4.9" "sed-4.9.tar.xz" ""
bp "Psmisc 23.7" "psmisc-23.7.tar.xz" ""
bp "Gettext 0.22.5" "gettext-0.22.5.tar.xz" "--disable-static --docdir=/usr/share/doc/gettext-0.22.5"
bp "Bison 3.8.2" "bison-3.8.2.tar.xz" "--docdir=/usr/share/doc/bison-3.8.2"
bp "Grep 3.11" "grep-3.11.tar.xz" ""
bp "GDBM 1.24" "gdbm-1.24.tar.gz" "--disable-static --enable-libgdbm-compat"
bp "Gperf 3.1" "gperf-3.1.tar.gz" "--docdir=/usr/share/doc/gperf-3.1"
bp "Expat 2.6.2" "expat-2.6.2.tar.xz" "--disable-static --docdir=/usr/share/doc/expat-2.6.2"

log_ok "Phase C complete - core packages done"
echo "PHASE_C_DONE" > /devforge/.phase-c-done
