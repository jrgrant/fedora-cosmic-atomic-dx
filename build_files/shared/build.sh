#!/usr/bin/bash
# build.sh — Primary build orchestrator for atomic-cosmic
#
# Adapted from bluefin/build_files/shared/build.sh.
# Strips GNOME-specific steps (build-gnome-extensions.sh).
# Always runs dx flavour — developer tooling is the whole point.

set -eoux pipefail

echo "::group:: Copy Files"

# Makes /opt writeable before any package installs touch it
if [ ! -L /opt ]; then
    mkdir -p /var/opt
    mv /opt/* /var/opt/ 2>/dev/null || true
    rm -rf /opt && ln -s /var/opt /opt
fi

# Speeds up local builds
dnf config-manager setopt keepcache=1

# We need to remove these packages here because lots of files we add
# from system_files override the rpm files
dnf remove -y ublue-os-luks ublue-os-just ublue-os-udev-rules ublue-os-signing ublue-os-update-services 2>/dev/null || true

# Keep *-logos in RPM DB for downstream package installations
dnf -y swap fedora-logos generic-logos 2>/dev/null || true
rpm --erase --nodeps --nodb generic-logos 2>/dev/null || true

# Copy Files to Container
rsync -rvK /ctx/system_files/shared/ /

echo "::endgroup::"

# Generate image-info.json
/ctx/build_files/base/00-image-info.sh

# Install Kernel and Akmods
/ctx/build_files/base/03-install-kernel-akmods.sh

# Install Additional Packages
/ctx/build_files/base/04-packages.sh

# Install Overrides and Fetch Install
/ctx/build_files/base/05-override-install.sh 2>/dev/null || true

# NOTE: build-gnome-extensions.sh omitted — COSMIC desktop, not GNOME

## late stage changes

# Systemd and Remove Items
/ctx/build_files/base/17-cleanup.sh

# Run workarounds
/ctx/build_files/base/18-workarounds.sh

# Regenerate initramfs
/ctx/build_files/base/19-initramfs.sh

# Always build DX — this project IS developer tooling
/ctx/build_files/shared/build-dx.sh

# Validate all repos are disabled before committing
/ctx/build_files/shared/validate-repos.sh
