#!/usr/bin/env bats
# US4: Homebrew and Flathub configured

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    CLEANUP="$PROJECT_ROOT/build_files/base/17-cleanup.sh"
}

@test "flatpak-nuke-fedora.service enabled" {
    grep -q 'flatpak-nuke-fedora' "$CLEANUP"
}

@test "flatpak-add-fedora-repos.service disabled" {
    grep -q 'flatpak-add-fedora-repos' "$CLEANUP"
}

@test "Flathub remote added" {
    grep -q 'flathub' "$CLEANUP"
}
