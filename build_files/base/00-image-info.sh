#!/usr/bin/bash
# 00-image-info.sh — Image identity metadata for atomic-cosmic
#
# Writes /usr/share/ublue-os/image-info.json and rewrites
# /usr/lib/os-release with atomic-cosmic identity.
# Adapted from bluefin/build_files/base/00-image-info.sh.

set -eoux pipefail

IMAGE_PRETTY_NAME="Atomic COSMIC DX"

mkdir -p /usr/share/ublue-os

cat > /usr/share/ublue-os/image-info.json <<EOF
{
  "image-name": "${IMAGE_NAME}",
  "image-flavor": "${IMAGE_FLAVOR}",
  "image-vendor": "${IMAGE_VENDOR}",
  "image-ref": "ostree-image-signed:docker://ghcr.io/jrgrant/atomic-cosmic",
  "image-tag": "${UBLUE_IMAGE_TAG}",
  "fedora-version": "${FEDORA_MAJOR_VERSION}",
  "base-image": "quay.io/fedora-ostree-desktops/cosmic-atomic"
}
EOF

# Rewrite os-release — keep ID=fedora for dnf/COPR chroot resolution
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${IMAGE_PRETTY_NAME}\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"${IMAGE_PRETTY_NAME}\"|" /usr/lib/os-release
sed -i "s|^VERSION_ID=.*|VERSION_ID=${FEDORA_MAJOR_VERSION}|" /usr/lib/os-release
# Do NOT change ID — must stay "fedora" for dnf5 COPR chroot resolution
