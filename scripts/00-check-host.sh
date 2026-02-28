#!/bin/bash
# ============================================================
# DevForge Linux - Host System Requirements Check
# ============================================================
# Verifies that WSL/host has all required tools for LFS build
# Based on LFS 12.2 Chapter 2.2
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config/distro.conf"

log_step "Checking Host System Requirements for $DISTRO_NAME Build"

ERRORS=0

check_version() {
    local name="$1"
    local cmd="$2"
    local min_version="$3"

    # Extract the actual binary name from the command
    local binary
    binary=$(echo "$cmd" | awk '{print $1}')

    if command -v "$binary" &>/dev/null; then
        local version
        version=$(eval "$cmd" 2>&1 | head -n1)
        log_ok "$name: $version"
    else
        log_error "$name: NOT FOUND (required: $min_version+)"
        ERRORS=$((ERRORS + 1))
    fi
}

check_command() {
    local name="$1"
    local cmd="$2"

    if command -v "$cmd" &>/dev/null; then
        log_ok "$name: found at $(command -v "$cmd")"
    else
        log_error "$name: NOT FOUND"
        ERRORS=$((ERRORS + 1))
    fi
}

# --- Required tools ---
log_info "Checking required tools..."
echo ""

check_version "Bash"       "bash --version | head -n1"          "3.2"
check_version "Binutils"   "ld --version | head -n1"            "2.13.1"
check_version "Bison"      "bison --version | head -n1"         "2.7"
check_version "Coreutils"  "chown --version | head -n1"         "8.1"
check_version "Diffutils"  "diff --version | head -n1"          "2.8.1"
check_version "Findutils"  "find --version | head -n1"          "4.2.31"
check_version "Gawk"       "gawk --version | head -n1"          "4.0.1"
check_version "GCC"        "gcc --version | head -n1"           "5.2"
check_version "G++"        "g++ --version | head -n1"           "5.2"
check_version "Grep"       "grep --version | head -n1"          "2.5.1a"
check_version "Gzip"       "gzip --version | head -n1"          "1.3.12"
check_version "M4"         "m4 --version | head -n1"            "1.4.10"
check_version "Make"       "make --version | head -n1"          "4.0"
check_version "Patch"      "patch --version | head -n1"         "2.5.4"
check_version "Perl"       "perl -V:version 2>/dev/null"        "5.8.8"
check_version "Python"     "python3 --version"                  "3.4"
check_version "Sed"        "sed --version | head -n1"           "4.1.5"
check_version "Tar"        "tar --version | head -n1"           "1.22"
check_version "Texinfo"    "makeinfo --version | head -n1"      "5.0"
check_version "Xz"         "xz --version | head -n1"            "5.0.0"

echo ""
log_info "Checking kernel and library..."
check_version "Linux Kernel" "uname -r"                         "4.19"
check_version "Glibc"       "ldd --version | head -n1"          "2.11"

# --- Check symlinks ---
echo ""
log_info "Checking required symlinks..."

if [ -h /bin/sh ] && readlink -f /bin/sh | grep -q bash; then
    log_ok "/bin/sh -> bash"
else
    log_error "/bin/sh does NOT point to bash"
    ERRORS=$((ERRORS + 1))
fi

if [ -h /usr/bin/yacc ] || [ -x /usr/bin/yacc ]; then
    log_ok "yacc found"
else
    log_warn "yacc not found (bison -y will be used)"
fi

if [ -h /usr/bin/awk ] || [ -x /usr/bin/awk ]; then
    if readlink -f /usr/bin/awk 2>/dev/null | grep -q gawk; then
        log_ok "/usr/bin/awk -> gawk"
    else
        log_ok "awk found ($(readlink -f /usr/bin/awk 2>/dev/null || echo 'direct'))"
    fi
else
    log_error "awk not found"
    ERRORS=$((ERRORS + 1))
fi

# --- Compile test ---
echo ""
log_info "Running compilation test..."

cat > /tmp/lfs_compile_test.c << 'TESTEOF'
#include <stdio.h>
int main() {
    printf("Compilation test OK\n");
    return 0;
}
TESTEOF

if gcc /tmp/lfs_compile_test.c -o /tmp/lfs_compile_test && /tmp/lfs_compile_test; then
    log_ok "C compilation works"
else
    log_error "C compilation FAILED"
    ERRORS=$((ERRORS + 1))
fi

cat > /tmp/lfs_compile_test.cpp << 'TESTEOF'
#include <iostream>
int main() {
    std::cout << "C++ compilation test OK" << std::endl;
    return 0;
}
TESTEOF

if g++ /tmp/lfs_compile_test.cpp -o /tmp/lfs_compile_test_cpp && /tmp/lfs_compile_test_cpp; then
    log_ok "C++ compilation works"
else
    log_error "C++ compilation FAILED"
    ERRORS=$((ERRORS + 1))
fi

rm -f /tmp/lfs_compile_test{,.c,.cpp,_cpp}

# --- Summary ---
echo ""
echo "============================================"
if [ $ERRORS -eq 0 ]; then
    log_ok "All checks passed! Host system is ready for LFS build."
else
    log_error "$ERRORS check(s) failed. Fix them before proceeding."
    echo ""
    log_info "To install missing packages on Ubuntu/WSL:"
    echo "  sudo apt update"
    echo "  sudo apt install -y build-essential bison gawk texinfo python3 m4"
    exit 1
fi
