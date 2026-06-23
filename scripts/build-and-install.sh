#!/usr/bin/env bash
# build-and-install.sh — Local build + install pipeline for atomic-cosmic
#
# Prunes old images, builds the Containerfile, loads into root's podman
# storage, and optionally rebases.
#
# Usage:
#   scripts/build-and-install.sh          # build + load only
#   scripts/build-and-install.sh --rebase # build + load + rebase + reboot

set -euo pipefail

REBASE=false
if [[ "${1:-}" == "--rebase" ]]; then
    REBASE=true
fi

IMAGE="fedora-cosmic-atomic-dx"
TAG="latest"
FULL_IMAGE="localhost/${IMAGE}:${TAG}"

echo "==> Pruning old podman storage"
podman system prune -af 2>/dev/null || true
sudo podman system prune -af 2>/dev/null || true

echo ""
echo "==> Building ${FULL_IMAGE}"
podman build --no-cache -t "${IMAGE}:${TAG}" .

echo ""
echo "==> Verifying image"
podman image exists "${IMAGE}:${TAG}" || {
    echo "ERROR: Build failed — image not found"
    exit 1
}
echo "  Image: $(podman images --format '{{.ID}}' "${IMAGE}:${TAG}" | head -1)"

echo ""
echo "==> Loading into root podman storage"
podman save "${IMAGE}:${TAG}" | sudo podman load

echo ""
echo "==> Pinning current deployment"
bash scripts/pin-current.sh

if $REBASE; then
    echo ""
    echo "==> Rebasing to ${FULL_IMAGE}"
    sudo rpm-ostree rebase "ostree-unverified-image:containers-storage:${FULL_IMAGE}"

    echo ""
    echo "==> Reboot to boot into the new image"
    echo "    sudo systemctl reboot"
    echo ""
    echo "    After reboot, run:"
    echo "    bash scripts/bootstrap.sh"
else
    echo ""
    echo "==> Image ready. To install:"
    echo "    sudo rpm-ostree rebase ostree-unverified-image:containers-storage:${FULL_IMAGE}"
    echo "    sudo systemctl reboot"
    echo ""
    echo "    Or re-run with: scripts/build-and-install.sh --rebase"
fi
