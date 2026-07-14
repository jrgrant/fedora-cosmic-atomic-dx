#!/usr/bin/bash
# clean-stage.sh — Remove build artifacts before committing the image
# Copied from bluefin/build_files/shared/clean-stage.sh

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

dnf config-manager setopt keepcache=0
dnf versionlock clear

systemctl disable flatpak-add-fedora-repos.service 2>/dev/null || true
systemctl mask flatpak-add-fedora-repos.service 2>/dev/null || true
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

rm -rf /.gitkeep
find /var/* -maxdepth 0 -type d \! -name cache \! -name opt -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;
rm -rf /tmp && mkdir -p /tmp
rm -rf /boot && mkdir -p /boot

echo "::endgroup::"
