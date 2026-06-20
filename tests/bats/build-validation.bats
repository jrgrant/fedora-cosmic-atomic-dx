#!/usr/bin/env bats
# Build validation test — runs podman build (CI only, not pre-commit)
#
# This test is separated from the structural tests because it:
# 1. Takes 10-30 minutes (pulls multi-GB base images)
# 2. Requires network access to quay.io, ghcr.io, and dnf repos
# 3. Is the definitive "does this actually work" gate
#
# Usage: BUILD_TEST=1 bats tests/bats/build-validation.bats
# In CI: always runs. Locally: opt-in via BUILD_TEST env var.

setup() {
    if [ -z "${BUILD_TEST:-}" ] && [ -z "${CI:-}" ]; then
        skip "BUILD_TEST not set — skipping heavy build test (set BUILD_TEST=1 or run in CI)"
    fi
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    IMAGE_TAG="atomic-cosmic-test:$(date +%s)"
}

@test "podman build completes without error" {
    run podman build --no-cache -t "$IMAGE_TAG" "$PROJECT_ROOT"
    [ "$status" -eq 0 ]
}

@test "bootc container lint passes" {
    run podman run --rm "$IMAGE_TAG" bootc container lint
    [ "$status" -eq 0 ]
}

@test "COSMIC packages inherited from FCA base" {
    for pkg in cosmic-session cosmic-term cosmic-edit; do
        run podman run --rm "$IMAGE_TAG" rpm -q "$pkg"
        [ "$status" -eq 0 ]
    done
}

@test "DX packages installed" {
    for pkg in docker-ce code tailscale distrobox; do
        run podman run --rm "$IMAGE_TAG" rpm -q "$pkg"
        [ "$status" -eq 0 ]
    done
}

@test "GNOME packages not installed" {
    for pkg in gnome-software gnome-extensions-app; do
        run podman run --rm "$IMAGE_TAG" rpm -q "$pkg"
        [ "$status" -ne 0 ]
    done
}

teardown() {
    podman rmi -f "$IMAGE_TAG" 2>/dev/null || true
}
