#!/usr/bin/env bash
# bootstrap.sh — Delegate to ujust bootstrap (single source of truth)
#
# All post-install logic lives in:
#   system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just
#
# Usage: ujust bootstrap

echo "==> Delegating to ujust bootstrap..."
exec ujust bootstrap
