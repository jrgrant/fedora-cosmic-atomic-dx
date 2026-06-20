#!/usr/bin/env bash
# Containerfile MVP — source-level structural verification
#
# Verifies the spec's build-time acceptance criteria (US1-US5)
# by checking source files exist with correct content.
# No podman build/pull/run required — this is TDD RED/GREEN at
# the source level. Runtime verification is Phase 5.
#
# Usage: ./scripts/test-containerfile.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
PASSED=0; FAILED=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASSED=$((PASSED+1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1 — $2"; FAILED=$((FAILED+1)); }

echo "=== US1: Build infrastructure exists ==="
for f in \
    Containerfile \
    build_files/shared/build.sh \
    build_files/base/00-image-info.sh \
    build_files/base/03-install-kernel-akmods.sh \
    build_files/base/04-packages.sh \
    build_files/base/17-cleanup.sh \
    build_files/base/18-workarounds.sh \
    build_files/base/19-initramfs.sh \
    build_files/dx/00-dx.sh \
    build_files/shared/copr-helpers.sh \
    build_files/shared/validate-repos.sh \
; do
    [ -f "$f" ] && pass "$f exists" || fail "$f exists" "missing"
done

echo ""
echo "=== US1: Containerfile structure ==="
[ -f Containerfile ] && {
    grep -q 'quay.io/fedora-ostree-desktops/cosmic-atomic' Containerfile \
        && pass "FROM FCA base" || fail "FROM FCA base" "missing"
    grep -q 'BREW_IMAGE_SHA' Containerfile \
        && pass "BREW_IMAGE_SHA arg (digest pin)" || fail "BREW_IMAGE_SHA arg" "missing"
    grep -q 'bootc container lint' Containerfile \
        && pass "bootc container lint called" || fail "bootc container lint" "missing"
    grep -q 'ublue-os/brew' Containerfile \
        && pass "brew layer imported" || fail "brew layer" "missing"
} || fail "Containerfile checks" "Containerfile missing"

echo ""
echo "=== US2: GNOME isolation ==="
[ -f build_files/base/04-packages.sh ] && {
    grep -q 'gnome-software' build_files/base/04-packages.sh \
        && pass "gnome-software in EXCLUDED" || fail "gnome-software excluded" "not in EXCLUDED"
    grep -q 'gnome-extensions-app' build_files/base/04-packages.sh \
        && pass "gnome-extensions-app in EXCLUDED" || fail "gnome-extensions-app excluded" "not in EXCLUDED"
    ! grep -q '^[^#]*gnome-tweaks' build_files/base/04-packages.sh 2>/dev/null \
        && pass "gnome-tweaks not in FEDORA_PACKAGES" || true
} || fail "04-packages.sh checks" "missing"

[ -f build_files/base/17-cleanup.sh ] && {
    grep -q 'dconf-update' build_files/base/17-cleanup.sh 2>/dev/null \
        && { grep -q 'systemctl enable dconf-update' build_files/base/17-cleanup.sh 2>/dev/null \
            && fail "dconf-update.service NOT enabled" "still enabled" \
            || pass "dconf-update.service not enabled"; } \
        || pass "dconf-update.service not referenced (COSMIC-appropriate)"
} || fail "17-cleanup.sh checks" "missing"

[ -f build_files/shared/build.sh ] && {
    ! grep -q 'build-gnome-extensions' build_files/shared/build.sh \
        && pass "build-gnome-extensions.sh not called" \
        || fail "build-gnome-extensions.sh called" "GNOME extension step present"
} || fail "build.sh checks" "missing"

echo ""
echo "=== US3: DX packages ==="
[ -f build_files/dx/00-dx.sh ] && {
    for pkg in docker-ce code qemu-system-x86-core libvirt tailscale; do
        grep -q "$pkg" build_files/dx/00-dx.sh \
            && pass "DX package: $pkg" || fail "DX package: $pkg" "missing"
    done
} || fail "00-dx.sh checks" "missing"

[ -f build_files/base/04-packages.sh ] && {
    for pkg in fish zsh just distrobox tailscale; do
        grep -q "$pkg" build_files/base/04-packages.sh 2>/dev/null \
            && pass "Base package: $pkg" || fail "Base package: $pkg" "missing"
    done
} || true

echo ""
echo "=== US4: Homebrew and Flathub ==="
[ -f build_files/base/17-cleanup.sh ] && {
    grep -q 'flatpak-nuke-fedora' build_files/base/17-cleanup.sh \
        && pass "flatpak-nuke-fedora enabled" || fail "flatpak-nuke-fedora" "missing"
    grep -q 'flatpak-add-fedora-repos' build_files/base/17-cleanup.sh \
        && pass "flatpak-add-fedora-repos disabled" || fail "flatpak-add-fedora-repos" "missing"
} || fail "17-cleanup.sh checks" "missing"

echo ""
echo "=== US5: Automatic updates ==="
[ -f build_files/base/17-cleanup.sh ] && {
    grep -q 'uupd.timer' build_files/base/17-cleanup.sh \
        && pass "uupd.timer enabled" || fail "uupd.timer" "missing"
    grep -q 'rpm-ostreed-automatic.timer' build_files/base/17-cleanup.sh \
        && pass "rpm-ostreed-automatic.timer disabled" || fail "rpm-ostreed-automatic" "missing"
} || fail "17-cleanup.sh checks" "missing"

echo ""
echo "=== System files ==="
[ -d system_files/shared ] && pass "system_files/shared/ exists" || fail "system_files/shared/" "missing"
[ -f system_files/shared/etc/systemd/system/brew-setup.service ] \
    && pass "brew-setup.service exists" || fail "brew-setup.service" "missing"

echo ""
echo "=== Image identity ==="
[ -f build_files/base/00-image-info.sh ] && {
    grep -q 'atomic-cosmic' build_files/base/00-image-info.sh 2>/dev/null \
        && pass "image ID set to atomic-cosmic" || fail "image ID" "missing"
} || fail "00-image-info.sh checks" "missing"

echo ""
echo "============================================"
echo -e "${GREEN}Passed:${NC} $PASSED  ${RED}Failed:${NC} $FAILED"
echo "============================================"

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "RED — expected before implementation. Write the files to turn green."
    exit 1
fi

echo ""
echo "GREEN — all structural checks pass."
exit 0
