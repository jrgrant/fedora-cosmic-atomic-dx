#!/usr/bin/bash
# 03-install-kernel-akmods.sh — Replace stock kernel with ublue-os/akmods
# Adapted from bluefin/build_files/base/03-install-kernel-akmods.sh.
# Desktop-agnostic — kernel swap works identically on COSMIC and GNOME.

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# Beta Updates Testing Repo
if [[ "${UBLUE_IMAGE_TAG}" == "beta" ]]; then
    dnf5 config-manager setopt updates-testing.enabled=1
fi

# Remove Existing Kernel
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
    rpm --erase $pkg --nodeps
done

# Kernel and AKMODS RPMs are mounted from the akmods/akmods_nvidia build stages
# via Containerfile --mount=type=bind. No skopeo copy needed — the RPMs are
# already present at /tmp/kernel-rpms, /tmp/akmods-rpms, /tmp/akmods-nv-rpms.
# Pattern from ublue/Containerfile:32-34 (FROM-based digest-pinned akmods).

# Install Kernel
dnf5 -y install \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm

# TODO: Figure out why akmods cache is pulling in akmods/kernel-devel
dnf5 -y install \
    /tmp/kernel-rpms/kernel-devel-*.rpm

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra

# Enable akmods repo (may not exist — kernel was installed from local RPMs)
if [ -f /etc/yum.repos.d/_copr_ublue-os-akmods.repo ]; then
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo
fi

# RPMFusion-dependent AKMODS (v4l2loopback)
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
dnf5 -y install \
    v4l2loopback /tmp/akmods-rpms/*.rpm
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

# NVIDIA AKMODS (triggered by IMAGE_NAME containing "nvidia")
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    # NVIDIA RPMs mounted from akmods_nvidia stage at /tmp/akmods-nv-rpms/
    IMAGE_NAME="${IMAGE_NAME:-fedora-cosmic-atomic-dx-nvidia}" AKMODNV_PATH="/tmp/akmods-nv-rpms" MULTILIB=0 /tmp/akmods-nv-rpms/nvidia-install.sh

    # Blacklist nouveau
    tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<KEOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
KEOF
fi

echo "::endgroup::"
