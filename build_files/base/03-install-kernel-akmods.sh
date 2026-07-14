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

# Fetch Common AKMODS & Kernel RPMS
skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)" dir:/tmp/akmods
AKMODS_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods/"$AKMODS_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods/

# Install Kernel
dnf5 -y install \
    /tmp/kernel-rpms/kernel-[0-9]*.rpm \
    /tmp/kernel-rpms/kernel-core-*.rpm \
    /tmp/kernel-rpms/kernel-modules-*.rpm

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
    v4l2loopback /tmp/akmods/kmods/*v4l2loopback*.rpm
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

# NVIDIA AKMODS (triggered by IMAGE_NAME containing "nvidia")
if [[ "${IMAGE_NAME}" =~ nvidia ]]; then
    # Fetch NVIDIA RPMs
    skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia-open:"${AKMODS_FLAVOR}"-"$(rpm -E %fedora)" dir:/tmp/akmods-rpms
    NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
    tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
    mv /tmp/rpms/* /tmp/akmods-rpms/

    # Install NVIDIA RPMs
    IMAGE_NAME="${IMAGE_NAME:-fedora-cosmic-atomic-dx-nvidia}" AKMODNV_PATH="/tmp/akmods-rpms" MULTILIB=0 /tmp/akmods-rpms/ublue-os/nvidia-install.sh

    # Blacklist nouveau
    tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<KEOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
KEOF
fi

echo "::endgroup::"
