#!/usr/bin/env bats
# US2: GNOME isolation — GNOME packages and services stripped

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    PKGS="$PROJECT_ROOT/build_files/base/04-packages.sh"
    CLEANUP="$PROJECT_ROOT/build_files/base/17-cleanup.sh"
    BUILD="$PROJECT_ROOT/build_files/shared/build.sh"
}

@test "gnome-software in EXCLUDED_PACKAGES" {
    grep -q 'gnome-software' "$PKGS"
}

@test "gnome-extensions-app in EXCLUDED_PACKAGES" {
    grep -q 'gnome-extensions-app' "$PKGS"
}

@test "gnome-software-rpm-ostree in EXCLUDED_PACKAGES" {
    grep -q 'gnome-software-rpm-ostree' "$PKGS"
}

@test "firefox in EXCLUDED_PACKAGES" {
    grep -q 'firefox' "$PKGS"
}

@test "fedora-chromium-config in EXCLUDED_PACKAGES" {
    grep -q 'fedora-chromium-config' "$PKGS"
}

@test "dconf-update.service not enabled in 17-cleanup.sh" {
    ! grep -q 'systemctl enable dconf-update.service' "$CLEANUP"
}

@test "build-gnome-extensions.sh not called from build.sh" {
    ! grep -q '/build-gnome-extensions' "$BUILD"
}
