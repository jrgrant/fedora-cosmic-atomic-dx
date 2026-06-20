#!/usr/bin/env bats
# US1: Build infrastructure exists — Containerfile and build scripts

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "Containerfile exists" {
    [ -f "$PROJECT_ROOT/Containerfile" ]
}

@test "build_files/shared/build.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/shared/build.sh" ]
}

@test "build_files/base/00-image-info.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/base/00-image-info.sh" ]
}

@test "build_files/base/03-install-kernel-akmods.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/base/03-install-kernel-akmods.sh" ]
}

@test "build_files/base/04-packages.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/base/04-packages.sh" ]
}

@test "build_files/base/17-cleanup.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/base/17-cleanup.sh" ]
}

@test "build_files/base/18-workarounds.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/base/18-workarounds.sh" ]
}

@test "build_files/base/19-initramfs.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/base/19-initramfs.sh" ]
}

@test "build_files/dx/00-dx.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/dx/00-dx.sh" ]
}

@test "build_files/shared/copr-helpers.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/shared/copr-helpers.sh" ]
}

@test "build_files/shared/validate-repos.sh exists" {
    [ -f "$PROJECT_ROOT/build_files/shared/validate-repos.sh" ]
}

@test "Containerfile FROM FCA base" {
    grep -q 'quay.io/fedora-ostree-desktops/cosmic-atomic' "$PROJECT_ROOT/Containerfile"
}

@test "Containerfile has BREW_IMAGE_SHA arg for digest pin" {
    grep -q 'BREW_IMAGE_SHA' "$PROJECT_ROOT/Containerfile"
}

@test "Containerfile imports brew layer" {
    grep -q 'ublue-os/brew' "$PROJECT_ROOT/Containerfile"
}

@test "Containerfile runs bootc container lint" {
    grep -q 'bootc container lint' "$PROJECT_ROOT/Containerfile"
}
