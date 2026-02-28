#!/bin/bash
# Resume toolchain build from GCC Pass 1 (Binutils Pass 1 already done)
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
    log_ok "Cleaned up $dir_name"
}

# --- GCC Pass 1 ---
build_gcc_pass1() {
    log_step "Building GCC $GCC_VERSION (Pass 1)"
    extract_and_cd "gcc-${GCC_VERSION}.tar.xz"

    tar -xf "../mpfr-${MPFR_VERSION}.tar.xz"
    mv -v "mpfr-${MPFR_VERSION}" mpfr
    tar -xf "../gmp-${GMP_VERSION}.tar.xz"
    mv -v "gmp-${GMP_VERSION}" gmp
    tar -xf "../mpc-${MPC_VERSION}.tar.gz"
    mv -v "mpc-${MPC_VERSION}" mpc

    case $(uname -m) in
        x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;;
    esac

    mkdir -v build && cd build
    ../configure \
        --target="$LFS_TGT" \
        --prefix="$LFS/tools" \
        --with-glibc-version=2.40 \
        --with-sysroot="$LFS" \
        --with-newlib \
        --without-headers \
        --enable-default-pie \
        --enable-default-ssp \
        --disable-nls \
        --disable-shared \
        --disable-multilib \
        --disable-threads \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --disable-libstdcxx \
        --enable-languages=c,c++

    make $MAKEFLAGS
    make install

    cd ..
    cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
        "$(dirname $($LFS_TGT-gcc -print-libgcc-file-name))/include/limits.h"

    cd "$LFS/sources"
    cleanup "gcc-${GCC_VERSION}"
    log_ok "GCC Pass 1 complete"
}

# --- Linux API Headers ---
build_linux_headers() {
    log_step "Installing Linux API Headers $LINUX_VERSION"
    extract_and_cd "linux-${LINUX_VERSION}.tar.xz"
    make mrproper
    make headers
    find usr/include -type f ! -name '*.h' -delete
    cp -rv usr/include "$LFS/usr"
    cd "$LFS/sources"
    cleanup "linux-${LINUX_VERSION}"
    log_ok "Linux API Headers installed"
}

# --- Glibc ---
build_glibc() {
    log_step "Building Glibc $GLIBC_VERSION"
    extract_and_cd "glibc-${GLIBC_VERSION}.tar.xz"

    case $(uname -m) in
        i?86)   ln -sfv ld-linux.so.2 "$LFS/lib/ld-lsb.so.3" ;;
        x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64"
                ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64/ld-lsb-x86-64.so.3" ;;
    esac

    patch -Np1 -i ../glibc-${GLIBC_VERSION}-fhs-1.patch
    mkdir -v build && cd build
    echo "rootsbindir=/usr/sbin" > configparms

    ../configure \
        --prefix=/usr \
        --host="$LFS_TGT" \
        --build="$(../scripts/config.guess)" \
        --enable-kernel=4.19 \
        --with-headers="$LFS/usr/include" \
        --disable-nscd \
        libc_cv_slibdir=/usr/lib

    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    sed '/RTLDLIST=/s@/usr@@g' -i "$LFS/usr/bin/ldd"

    log_info "Glibc sanity check..."
    echo 'int main(){}' | "$LFS_TGT-gcc" -xc -
    readelf -l a.out | grep ld-linux && log_ok "Glibc sanity check passed"
    rm -v a.out

    cd "$LFS/sources"
    cleanup "glibc-${GLIBC_VERSION}"
    log_ok "Glibc complete"
}

# --- Libstdc++ ---
build_libstdcxx() {
    log_step "Building Libstdc++ (from GCC $GCC_VERSION)"
    extract_and_cd "gcc-${GCC_VERSION}.tar.xz"
    mkdir -v build && cd build

    ../libstdc++-v3/configure \
        --host="$LFS_TGT" \
        --build="$(../config.guess)" \
        --prefix=/usr \
        --disable-multilib \
        --disable-nls \
        --disable-libstdcxx-pch \
        --with-gxx-include-dir="/tools/$LFS_TGT/include/c++/$GCC_VERSION"

    make $MAKEFLAGS
    make DESTDIR="$LFS" install
    rm -v "$LFS/usr/lib/lib"{stdc++{,exp,fs},supc++}.la

    cd "$LFS/sources"
    cleanup "gcc-${GCC_VERSION}"
    log_ok "Libstdc++ complete"
}

# --- Main ---
log_step "DevForge Linux - Resuming Toolchain Build (skipping Binutils Pass 1)"
START_TIME=$(date +%s)

build_gcc_pass1
build_linux_headers
build_glibc
build_libstdcxx

END_TIME=$(date +%s)
ELAPSED=$(( (END_TIME - START_TIME) / 60 ))

log_step "Cross-Toolchain Build Complete!"
log_ok "Total time: ${ELAPSED} minutes"
log_info "Next: bash 04-cross-tools.sh"
