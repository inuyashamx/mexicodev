#!/bin/bash
# ============================================================
# DevForge Linux - Download Source Packages
# ============================================================
# Downloads all LFS 12.2 source tarballs and patches
# Uses curl with timeouts for reliability
# ============================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../config/distro.conf"
source "$SCRIPT_DIR/../config/packages.sh"

log_step "Downloading LFS Source Packages"

DOWNLOAD_DIR="$LFS/sources"

if [ ! -d "$DOWNLOAD_DIR" ]; then
    log_error "$DOWNLOAD_DIR does not exist. Run 01-setup-env.sh first."
    exit 1
fi

TOTAL=${#PACKAGES[@]}
CURRENT=0
FAILED=0
SKIPPED=0
FAILED_LIST=""

# --- Download packages ---
for entry in "${PACKAGES[@]}"; do
    IFS='|' read -r name version url md5 <<< "$entry"
    CURRENT=$((CURRENT + 1))
    filename=$(basename "$url")

    if [ -f "$DOWNLOAD_DIR/$filename" ]; then
        echo -e "${BLUE}[$CURRENT/$TOTAL]${NC} $name-$version ${YELLOW}(cached)${NC}"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    echo -ne "${BLUE}[$CURRENT/$TOTAL]${NC} $name-$version... "

    if curl -fSL --connect-timeout 15 --max-time 300 --retry 2 \
         -o "$DOWNLOAD_DIR/$filename" "$url" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        rm -f "$DOWNLOAD_DIR/$filename"
        echo -e "${RED}FAILED${NC}"
        FAILED_LIST="$FAILED_LIST $name-$version"
        FAILED=$((FAILED + 1))
    fi
done

# --- Download patches ---
echo ""
log_info "Downloading patches..."

for entry in "${PATCHES[@]}"; do
    IFS='|' read -r name url <<< "$entry"

    if [ -f "$DOWNLOAD_DIR/$name" ]; then
        echo -e "  $name ${YELLOW}(cached)${NC}"
        continue
    fi

    echo -ne "  $name... "
    if curl -fSL --connect-timeout 15 --max-time 60 --retry 2 \
         -o "$DOWNLOAD_DIR/$name" "$url" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        rm -f "$DOWNLOAD_DIR/$name"
        echo -e "${RED}FAILED${NC}"
        FAILED=$((FAILED + 1))
    fi
done

# --- Summary ---
echo ""
log_step "Download Summary"
log_ok "Total packages: $TOTAL"
[ $SKIPPED -gt 0 ] && log_ok "Cached (skipped): $SKIPPED"
DOWNLOADED=$((TOTAL - SKIPPED - FAILED))
[ $DOWNLOADED -gt 0 ] && log_ok "Downloaded: $DOWNLOADED"

if [ $FAILED -gt 0 ]; then
    log_error "Failed ($FAILED):$FAILED_LIST"
    log_info "Re-run this script to retry failed downloads."
fi

echo ""
TOTAL_SIZE=$(du -sh "$DOWNLOAD_DIR" 2>/dev/null | awk '{print $1}')
log_info "Total size: $TOTAL_SIZE"

if [ $FAILED -eq 0 ]; then
    log_ok "All sources ready!"
    log_info "Next: su - lfs && bash 03-toolchain.sh"
else
    exit 1
fi
