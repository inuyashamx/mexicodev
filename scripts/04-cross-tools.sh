#!/bin/bash
# ============================================================
# DevForge Linux - Cross-Compile Temporary Tools (LFS Ch. 6)
# ============================================================
# Cross-compiles essential temporary tools using the
# toolchain built in Chapter 5.
# Run as user 'lfs'
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config/distro.conf"

cd "$LFS/sources"

extract_and_cd() {
    local tarball="$1"
    local dir_name="${tarball%.tar.*}"
    log_info "Extracting $tarball..."
    tar -xf "$tarball"
    cd "$dir_name"
}

cleanup() {
    local dir_name="$1"
    cd "$LFS/sources"
    rm -rf "$dir_name"
    log_ok "Cleaned $dir_name"
}

# ============================================================
# 6.2 M4
# ============================================================
build_m4() {
    log_step "Building M4 1.4.19"
    extract_and_cd "m4-1.4.19.tar.xz"
    ./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "m4-1.4.19"
}

# ============================================================
# 6.3 Ncurses
# ============================================================
build_ncurses() {
    log_step "Building Ncurses 6.5"
    extract_and_cd "ncurses-6.5.tar.gz"

    # Build tic for host
    mkdir build-host && cd build-host
    ../configure
    make -C include
    make -C progs tic
    cd ..

    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(./config.guess)" \
        --mandir=/usr/share/man \
        --with-manpage-format=normal \
        --with-shared \
        --without-normal \
        --with-cxx-shared \
        --without-debug \
        --without-ada \
        --disable-stripping

    make $MAKEFLAGS
    make DESTDIR="$LFS" TIC_PATH="$(pwd)/build-host/progs/tic" install
    ln -sv libncursesw.so "$LFS/usr/lib/libncurses.so"
    sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "$LFS/usr/include/curses.h"

    cleanup "ncurses-6.5"
}

# ============================================================
# 6.4 Bash
# ============================================================
build_bash() {
    log_step "Building Bash 5.2.32"
    extract_and_cd "bash-5.2.32.tar.gz"
    ./configure \
        --prefix=/usr \
        --build="$(sh support/config.guess)" \
        --host="$LFS_TGT" \
        --without-bash-malloc \
        bash_cv_strtold_broken=no
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    ln -sv bash "$LFS/bin/sh"
    cleanup "bash-5.2.32"
}

# ============================================================
# 6.5 Coreutils
# ============================================================
build_coreutils() {
    log_step "Building Coreutils 9.5"
    extract_and_cd "coreutils-9.5.tar.xz"
    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(build-aux/config.guess)" \
        --enable-install-program=hostname \
        --enable-no-install-program=kill,uptime
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    mv -v "$LFS/usr/bin/chroot" "$LFS/usr/sbin"
    mkdir -pv "$LFS/usr/share/man/man8"
    mv -v "$LFS/usr/share/man/man1/chroot.1" "$LFS/usr/share/man/man8/chroot.8"
    sed -i 's/"1"/"8"/' "$LFS/usr/share/man/man8/chroot.8"
    cleanup "coreutils-9.5"
}

# ============================================================
# 6.6 Diffutils
# ============================================================
build_diffutils() {
    log_step "Building Diffutils 3.10"
    extract_and_cd "diffutils-3.10.tar.xz"
    ./configure --prefix=/usr --host="$LFS_TGT" --build="$(./build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "diffutils-3.10"
}

# ============================================================
# 6.7 File
# ============================================================
build_file() {
    log_step "Building File 5.45"
    extract_and_cd "file-5.45.tar.gz"

    mkdir build-host && cd build-host
    ../configure --disable-bzlib --disable-libseccomp \
        --disable-xzlib --disable-zlib
    make
    cd ..

    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(./config.guess)"
    make FILE_COMPILE="$(pwd)/build-host/src/file" $MAKEFLAGS
    make DESTDIR="$LFS" install
    rm -v "$LFS/usr/lib/libmagic.la"

    cleanup "file-5.45"
}

# ============================================================
# 6.8 Findutils
# ============================================================
build_findutils() {
    log_step "Building Findutils 4.10.0"
    extract_and_cd "findutils-4.10.0.tar.xz"
    ./configure \
        --prefix=/usr \
        --localstatedir=/var/lib/locate \
        --host="$LFS_TGT" \
        --build="$(build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "findutils-4.10.0"
}

# ============================================================
# 6.9 Gawk
# ============================================================
build_gawk() {
    log_step "Building Gawk 5.3.1"
    extract_and_cd "gawk-5.3.1.tar.xz"
    sed -i 's/extras//' Makefile.in
    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "gawk-5.3.1"
}

# ============================================================
# 6.10 Grep
# ============================================================
build_grep() {
    log_step "Building Grep 3.11"
    extract_and_cd "grep-3.11.tar.xz"
    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(./build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "grep-3.11"
}

# ============================================================
# 6.11 Gzip
# ============================================================
build_gzip() {
    log_step "Building Gzip 1.13"
    extract_and_cd "gzip-1.13.tar.xz"
    ./configure --prefix=/usr --host="$LFS_TGT"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "gzip-1.13"
}

# ============================================================
# 6.12 Make
# ============================================================
build_make() {
    log_step "Building Make 4.4.1"
    extract_and_cd "make-4.4.1.tar.gz"
    ./configure \
        --prefix=/usr \
        --without-guile \
        --host="$LFS_TGT" \
        --build="$(build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "make-4.4.1"
}

# ============================================================
# 6.13 Patch
# ============================================================
build_patch() {
    log_step "Building Patch 2.7.6"
    extract_and_cd "patch-2.7.6.tar.xz"
    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "patch-2.7.6"
}

# ============================================================
# 6.14 Sed
# ============================================================
build_sed() {
    log_step "Building Sed 4.9"
    extract_and_cd "sed-4.9.tar.xz"
    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(./build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "sed-4.9"
}

# ============================================================
# 6.15 Tar
# ============================================================
build_tar() {
    log_step "Building Tar 1.35"
    extract_and_cd "tar-1.35.tar.xz"
    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(build-aux/config.guess)"
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    cleanup "tar-1.35"
}

# ============================================================
# 6.16 Xz
# ============================================================
build_xz() {
    log_step "Building Xz 5.6.2"
    extract_and_cd "xz-5.6.2.tar.xz"
    ./configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(build-aux/config.guess)" \
        --disable-static \
        --docdir=/usr/share/doc/xz-5.6.2
    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    rm -v "$LFS/usr/lib/liblzma.la"
    cleanup "xz-5.6.2"
}

# ============================================================
# 6.17 Binutils Pass 2
# ============================================================
build_binutils_pass2() {
    log_step "Building Binutils $BINUTILS_VERSION (Pass 2)"
    extract_and_cd "binutils-${BINUTILS_VERSION}.tar.xz"

    sed '6009s/$add_dir//' -i ltmain.sh

    mkdir -v build && cd build
    ../configure \
        --prefix=/usr \
        --build="$(../config.guess)" \
        --host="$LFS_TGT" \
        --disable-nls \
        --enable-shared \
        --enable-gprofng=no \
        --disable-werror \
        --enable-64-bit-bfd \
        --enable-new-dtags \
        --enable-default-hash-style=gnu
    make $MAKEFLAGS
    make DESTDIR="$LFS" install

    rm -v "$LFS/usr/lib/lib"{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

    cleanup "binutils-${BINUTILS_VERSION}"
}

# ============================================================
# 6.18 GCC Pass 2
# ============================================================
build_gcc_pass2() {
    log_step "Building GCC $GCC_VERSION (Pass 2)"
    extract_and_cd "gcc-${GCC_VERSION}.tar.xz"

    tar -xf "../mpfr-${MPFR_VERSION}.tar.xz"
    mv -v "mpfr-${MPFR_VERSION}" mpfr
    tar -xf "../gmp-${GMP_VERSION}.tar.xz"
    mv -v "gmp-${GMP_VERSION}" gmp
    tar -xf "../mpc-${MPC_VERSION}.tar.gz"
    mv -v "mpc-${MPC_VERSION}" mpc

    case $(uname -m) in
        x86_64)
            sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
            ;;
    esac

    sed '/thread_header =/s/@.*@/gthr-posix.h/' \
        -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

    mkdir -v build && cd build

    ../configure \
        --build="$(../config.guess)" \
        --host="$LFS_TGT" \
        --target="$LFS_TGT" \
        LDFLAGS_FOR_TARGET="-L$PWD/$LFS_TGT/libgcc" \
        --prefix=/usr \
        --with-build-sysroot="$LFS" \
        --enable-default-pie \
        --enable-default-ssp \
        --disable-nls \
        --disable-multilib \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libsanitizer \
        --disable-libssp \
        --disable-libvtv \
        --enable-languages=c,c++

    make $MAKEFLAGS
    make DESTDIR="$LFS" install

    ln -sv gcc "$LFS/usr/bin/cc"

    cleanup "gcc-${GCC_VERSION}"
}

# ============================================================
# Main Build Sequence
# ============================================================
log_step "DevForge Linux - Cross-Compiling Temporary Tools"

START_TIME=$(date +%s)

build_m4
build_ncurses
build_bash
build_coreutils
build_diffutils
build_file
build_findutils
build_gawk
build_grep
build_gzip
build_make
build_patch
build_sed
build_tar
build_xz
build_binutils_pass2
build_gcc_pass2

END_TIME=$(date +%s)
ELAPSED=$(( (END_TIME - START_TIME) / 60 ))

log_step "Temporary Tools Build Complete!"
log_ok "Total time: ${ELAPSED} minutes"
log_info "Next: sudo bash 05-chroot.sh"
