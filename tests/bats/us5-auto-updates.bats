#!/usr/bin/env bats
# US5: Automatic updates via uupd

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    CLEANUP="$PROJECT_ROOT/build_files/base/17-cleanup.sh"
}

@test "uupd.timer enabled" {
    grep -q 'uupd.timer' "$CLEANUP"
}

@test "rpm-ostreed-automatic.timer disabled" {
    grep -q 'rpm-ostreed-automatic.timer' "$CLEANUP"
}
