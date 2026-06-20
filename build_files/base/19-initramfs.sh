#!/usr/bin/bash
# 19-initramfs.sh — Regenerate initramfs for the new kernel
# Adapted from bluefin/build_files/base/19-initramfs.sh (unchanged).

set -eoux pipefail

KERNEL_VERSION="$(rpm -q --queryformat="%{evr}.%{arch}" kernel-core)"

/usr/bin/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add ostree -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"
