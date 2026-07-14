#!/usr/bin/bash
# 04-packages.sh — Base packages for atomic-cosmic
# Adapted from bluefin/build_files/base/04-packages.sh.
# GNOME-specific packages stripped for COSMIC compatibility.

echo "::group:: ===$(basename "$0")==="

set -ouex pipefail

source /ctx/build_files/shared/copr-helpers.sh

# Base packages from Fedora repos — COSMIC-compatible subset
FEDORA_PACKAGES=(
    adwaita-fonts-all
    bash-color-prompt
    bcache-tools
    bootc
    borgbackup
    containerd
    cryfs
    davfs2
    ddcutil
    distrobox
    evtest
    fastfetch
    firewall-config
    fish
    foo2zjs
    fuse-encfs
    gcc
    gcc-c++
    git-credential-libsecret
    glow
    gum
    hplip
    ifuse
    igt-gpu-tools
    input-remapper
    iwd
    jetbrains-mono-fonts-all
    just
    krb5-workstation
    libappindicator-gtk3
    libayatana-appindicator-gtk3
    libgda
    libgda-sqlite
    libimobiledevice
    libratbag-ratbagd
    libxcrypt-compat
    lm_sensors
    make
    mesa-libGLU
    oddjob-mkhomedir
    opendyslexic-fonts
    openssh-askpass
    powerstat
    powertop
    printer-driver-brlaser
    pulseaudio-utils
    python3-pip
    python3-pygit2
    rclone
    restic
    samba
    samba-dcerpc
    samba-ldb-ldap-modules
    samba-winbind-clients
    samba-winbind-modules
    seahorse
    setools-console
    sssd-nfs-idmap
    switcheroo-control
    tmux
    usbip
    usbmuxd
    waypipe
    wireguard-tools
    wl-clipboard
    xdg-terminal-exec
    xprop
    zenity
    zsh
)

# Install all Fedora packages
echo "Installing ${#FEDORA_PACKAGES[@]} packages from Fedora repos..."
dnf -y install "${FEDORA_PACKAGES[@]}"

# Tailscale
dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
dnf config-manager setopt tailscale-stable.enabled=0
dnf -y install --enablerepo='tailscale-stable' tailscale

# Nerd Fonts from COPR
copr_install_isolated "che/nerd-fonts" "nerd-fonts"

# uupd from ublue-os COPR
copr_install_isolated "ublue-os/packages" "uupd" "ublue-os-just"

# Packages to exclude — GNOME-specific and unwanted
EXCLUDED_PACKAGES=(
    cosign
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-gnome
    gnome-extensions-app
    gnome-shell-extension-background-logo
    gnome-software
    gnome-software-rpm-ostree
    gnome-terminal-nautilus
    podman-docker
    yelp
)

# Remove excluded packages if installed
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    readarray -t INSTALLED_EXCLUDED < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null || true)
    if [[ "${#INSTALLED_EXCLUDED[@]}" -gt 0 ]]; then
        dnf -y remove "${INSTALLED_EXCLUDED[@]}"
    else
        echo "No excluded packages found to remove."
    fi
fi

echo "::endgroup::"
