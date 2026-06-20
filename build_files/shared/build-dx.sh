#!/usr/bin/bash
# build-dx.sh — Developer experience build step
# Adapted from bluefin/build_files/shared/build-dx.sh
# Copies dx system_files and runs dx package installation.

set -xeou pipefail

echo "::group:: Copy DX Files"
rsync -rvK /ctx/system_files/dx/ / 2>/dev/null || true
echo "::endgroup::"

# Load iptable_nat for docker-in-docker
mkdir -p /etc/modules-load.d
echo "iptable_nat" > /etc/modules-load.d/ip_tables.conf

# Install DX packages
/ctx/build_files/dx/00-dx.sh

# Validate repos after DX install
/ctx/build_files/shared/validate-repos.sh

# Clean up build artifacts
echo "::group:: Cleanup"
/ctx/build_files/shared/clean-stage.sh
echo "::endgroup::"
