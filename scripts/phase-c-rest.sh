#!/bin/bash
set -e
MAKEFLAGS="-j$(nproc)"
cd /sources

bp() {
    local name="$1" tarball="$2" args="$3"
    echo "=== $name ==="
    local dir="${tarball%.tar.*}"
    tar -xf "$tarball" && cd "$dir"
    if [ -f configure ]; then
        ./configure --prefix=/usr $args
        make $MAKEFLAGS && make install
    fi
    cd /sources && rm -rf "$dir"
    echo "$name OK"
}

bp "GMP 6.3.0" "gmp-6.3.0.tar.xz" "--enable-cxx --disable-static"
bp "MPFR 4.2.1" "mpfr-4.2.1.tar.xz" "--disable-static --enable-thread-safe"
bp "MPC 1.3.1" "mpc-1.3.1.tar.gz" "--disable-static"
bp "Attr 2.5.2" "attr-2.5.2.tar.gz" "--disable-static --sysconfdir=/etc"
bp "Acl 2.3.2" "acl-2.3.2.tar.xz" "--disable-static"

echo "=== Libcap 2.70 ==="
tar -xf libcap-2.70.tar.xz && cd libcap-2.70
sed -i '/install -m.*STA/d' libcap/Makefile
make prefix=/usr lib=lib $MAKEFLAGS
make prefix=/usr lib=lib install
cd /sources && rm -rf libcap-2.70
echo "Libcap OK"

bp "Libxcrypt 4.4.36" "libxcrypt-4.4.36.tar.xz" "--enable-hashes=strong,glibc --enable-obsolete-api=no --disable-static --disable-failure-tokens"
bp "Sed 4.9" "sed-4.9.tar.xz" ""
bp "Psmisc 23.7" "psmisc-23.7.tar.xz" ""
bp "Gettext 0.22.5" "gettext-0.22.5.tar.xz" "--disable-static"
bp "Bison 3.8.2" "bison-3.8.2.tar.xz" ""
bp "Grep 3.11" "grep-3.11.tar.xz" ""
bp "GDBM 1.24" "gdbm-1.24.tar.gz" "--disable-static --enable-libgdbm-compat"
bp "Gperf 3.1" "gperf-3.1.tar.gz" ""
bp "Expat 2.6.2" "expat-2.6.2.tar.xz" "--disable-static"

echo "DONE" > /devforge/.phase-c-done
echo "PHASE C COMPLETE"
