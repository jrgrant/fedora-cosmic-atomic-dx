#!/usr/bin/bash
# 05-cosmic-upgrade.sh — Upgrade COSMIC from adil192 COPR (newer builds)
#
# The Fedora 44 repos ship COSMIC 1.1.0. The adil192 COPR provides newer
# builds (1.2+). This script temporarily enables the COPR, upgrades COSMIC
# packages, then removes the repo — keeping the image clean.
#
# The repo is removed rather than disabled because validate-repos.sh fails
# on any enabled third-party repo.

set -eoux pipefail

COPR_REPO="https://copr.fedorainfracloud.org/coprs/adil192/cosmic-epoch/repo/fedora-44/adil192-cosmic-epoch-fedora-44.repo"
REPO_FILE="/etc/yum.repos.d/adil192-cosmic-epoch.repo"

# Add the COPR repo
curl -fsSL "$COPR_REPO" -o "$REPO_FILE"
echo "Added COPR repo: $REPO_FILE"

# Upgrade COSMIC packages from the COPR
dnf upgrade -y cosmic-\* xdg-desktop-portal-cosmic cutecosmic\* 2>/dev/null || true

# Remove the repo — don't leave third-party repos enabled
rm -f "$REPO_FILE"
echo "Removed COPR repo"
