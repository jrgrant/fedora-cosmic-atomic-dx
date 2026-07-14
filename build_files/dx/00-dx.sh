#!/usr/bin/bash
# 00-dx.sh — Developer experience packages for atomic-cosmic
# Adapted from bluefin/build_files/dx/00-dx.sh.
# Desktop-agnostic — all packages work on COSMIC.

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

source /ctx/build_files/shared/copr-helpers.sh

# DX packages from Fedora repos — common to all versions
FEDORA_PACKAGES=(
    android-tools
    bcc
    bpftop
    bpftrace
    cascadia-code-fonts
    cockpit-bridge
    cockpit-machines
    cockpit-networkmanager
    cockpit-ostree
    cockpit-podman
    cockpit-selinux
    cockpit-storaged
    cockpit-system
    dbus-x11
    edk2-ovmf
    flatpak-builder
    genisoimage
    git-subtree
    git-svn
    iotop
    libvirt
    libvirt-nss
    nicstat
    numactl
    osbuild-selinux
    p7zip
    p7zip-plugins
    podman-compose
    podman-machine
    podman-tui
    qemu
    qemu-char-spice
    qemu-device-display-virtio-gpu
    qemu-device-display-virtio-vga
    qemu-device-usb-redirect
    qemu-img
    qemu-system-x86-core
    qemu-user-binfmt
    qemu-user-static
    sysprof
    incus
    incus-agent
    lxc
    tiptop
    trace-cmd
    udica
    util-linux-script
    virt-manager
    virt-v2v
    virt-viewer
    wtype
    ydotool
)

echo "Installing ${#FEDORA_PACKAGES[@]} DX packages from Fedora repos..."
dnf5 -y install "${FEDORA_PACKAGES[@]}"

# AMD GPU compute (skip on nvidia)
if [[ ! "${IMAGE_NAME}" =~ nvidia ]]; then
  dnf install -y \
    rocm-hip \
    rocm-opencl \
    rocm-smi \
    rocminfo
fi

# Docker CE
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
dnf -y install --enablerepo=docker-ce-stable \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    docker-model-plugin

# Visual Studio Code (self-updating /var/opt install)
echo "::group:: Installing VS Code to /var/opt"
VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
curl -fsSL "$VSCODE_URL" -o /tmp/vscode.tar.gz
mkdir -p /var/opt/vscode
tar -xzf /tmp/vscode.tar.gz -C /var/opt/vscode --strip-components=1
ln -sf /var/opt/vscode/bin/code /usr/local/bin/code
rm -f /tmp/vscode.tar.gz
echo "::endgroup::"
