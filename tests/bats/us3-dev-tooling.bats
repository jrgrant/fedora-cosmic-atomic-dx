#!/usr/bin/env bats
# US3: Developer tooling present — DX and base packages

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    DX="$PROJECT_ROOT/build_files/dx/00-dx.sh"
    BASE="$PROJECT_ROOT/build_files/base/04-packages.sh"
}

@test "DX: docker-ce" { grep -q 'docker-ce' "$DX"; }
@test "DX: code (VS Code)" { grep -q 'code' "$DX"; }
@test "DX: qemu-system-x86-core" { grep -q 'qemu-system-x86-core' "$DX"; }
@test "DX: libvirt" { grep -q 'libvirt' "$DX"; }
@test "DX: tailscale" { grep -qr 'tailscale' "$DX" "$BASE"; }
@test "DX: virt-manager" { grep -q 'virt-manager' "$DX"; }
@test "DX: podman-compose" { grep -q 'podman-compose' "$DX"; }
@test "DX: incus" { grep -q 'incus' "$DX"; }
@test "DX: cockpit" { grep -q 'cockpit' "$DX"; }

@test "Base: fish" { grep -q 'fish' "$BASE"; }
@test "Base: zsh" { grep -q 'zsh' "$BASE"; }
@test "Base: distrobox" { grep -q 'distrobox' "$BASE"; }
@test "Base: just" { grep -q '\<just\>' "$BASE"; }
@test "Base: tmux" { grep -q 'tmux' "$BASE"; }
