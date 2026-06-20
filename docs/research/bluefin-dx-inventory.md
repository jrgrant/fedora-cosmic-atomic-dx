# Bluefin DX Inventory — What to Port to FCA

**Date**: 2026-06-20
**Source**: `bluefin/build_files/` and `bluefin/system_files/`

---

## Base Packages (`04-packages.sh`)

### Keep (desktop-agnostic)

| Package | Function | Why port |
|---|---|---|
| `fish` | Shell | Better interactive shell |
| `zsh` | Shell | Alternative shell |
| `just` | Task runner | Bluefin's `ujust` recipes depend on it |
| `fastfetch` | System info | Nice-to-have |
| `glow` | Markdown renderer | Terminal-friendly docs |
| `gum` | TUI toolkit | Used by justfiles |
| `bootc` | Bootable containers | Required for OCI image management |
| `distrobox` | Dev containers | Not in 04-packages.sh but pulled via ublue base |
| `tailscale` | Mesh VPN | Developer networking |
| `iwd` | WiFi daemon | Better WiFi stack |
| `krb5-workstation` | Kerberos | Enterprise auth |
| `samba` (full stack) | SMB/CIFS | File sharing |
| `rclone`, `restic`, `borgbackup` | Backup/sync | Dev data management |
| `tmux` | Terminal multiplexer | Standard dev tool |
| `git-credential-libsecret` | Git credential helper | Keyring integration |
| `python3-pip`, `python3-pygit2` | Python tooling | Development |
| `gcc`, `gcc-c++`, `make` | Compilers | Build toolchain |
| `adw-gtk3-theme` | Theme | Needed for GTK apps to look right |
| `wireguard-tools` | VPN | Networking |
| `wl-clipboard`, `waypipe` | Wayland utilities | Required for COSMIC |
| `openssh-askpass` | SSH GUI passphrase | Keyring integration |
| `setools-console` | SELinux tools | System management |
| `jetbrains-mono-fonts-all`, `adwaita-fonts-all` | Fonts | Developer fonts |

### Skip (GNOME-specific or irrelevant)

| Package | Reason |
|---|---|
| `gnome-tweaks` | GNOME-only |
| `nautilus-gsconnect` | GNOME Files extension |
| `gnome-extensions-app` (excluded list) | GNOME-only |
| `gnome-shell-extension-background-logo` (excluded) | GNOME-only |
| `gnome-software`, `gnome-software-rpm-ostree` (excluded) | GNOME Software |
| `gnome-terminal-nautilus` (excluded) | GNOME-only |
| `firefox`, `firefox-langpacks` (excluded) | We'll install browser via brew |
| `fedora-chromium-config`, `fedora-chromium-config-gnome` (excluded) | GNOME-specific config |
| `evolution-ews-core` | GNOME Evolution |
| `ibus-mozc`, `mozc` | Japanese IME (keep if needed, skip otherwise) |
| `cascadia-code-fonts` | Already in dx packages below |
| `autofs` | Optional |

### Check FCA baseline first

These may already be in FCA — don't duplicate:

- `podman`, `buildah`, `skopeo` (FCA has podman)
- `NetworkManager`, `systemd`, `firewalld` (FCA has these)
- `mesa-libGLU`, `mesa-dri-drivers` (FCA has mesa)
- `pipewire*` (FCA has pipewire)

---

## DX Packages (`dx/00-dx.sh`)

### Container & Virtualisation

| Package | Function |
|---|---|
| `docker-ce`, `docker-ce-cli`, `docker-buildx-plugin`, `docker-compose-plugin` | Docker engine |
| `containerd.io` | Container runtime |
| `podman-compose` | docker-compose for podman |
| `podman-machine`, `podman-tui` | Podman management |
| `qemu`, `qemu-img`, `qemu-system-x86-core`, `qemu-char-spice`, `qemu-device-display-*` | Full QEMU stack |
| `libvirt`, `virt-manager`, `virt-viewer`, `virt-v2v` | Virtualisation management |
| `edk2-ovmf` | UEFI firmware for VMs |
| `incus`, `incus-agent`, `lxc` | System containers |
| `cockpit-machines`, `cockpit-networkmanager`, `cockpit-ostree`, `cockpit-podman`, `cockpit-selinux`, `cockpit-storaged`, `cockpit-system`, `cockpit-bridge` | Web-based system management |

### Development Tooling

| Package | Function |
|---|---|
| `code` (VS Code) | IDE — from Microsoft repo |
| `flatpak-builder` | Flatpak development |
| `git-subtree`, `git-svn` | Git extensions |
| `android-tools` | Android development |
| `sysprof` | System profiling |
| `bpftrace`, `bpfmon` | eBPF tracing |
| `bcc` | BPF compiler collection |
| `trace-cmd` | Ftrace frontend |
| `udica` | SELinux policy generator |
| `iotop`, `nicstat`, `tiptop`, `numactl` | Performance monitoring |
| `dbus-x11` | D-Bus X11 (needed for some dev tools) |

### Media & Encoding

| Package | Function |
|---|---|
| `p7zip`, `p7zip-plugins` | Archive extraction |
| `genisoimage` | ISO creation |
| `cascadia-code-fonts` | Developer font |
| `rocm-hip`, `rocm-opencl`, `rocm-smi`, `rocminfo` | AMD GPU compute (skip on NVIDIA) |

---

## Excluded Packages (remove from FCA base)

| Package | Reason |
|---|---|
| `cosign` | Replaced by brew |
| `fedora-bookmarks` | Fedora branding |
| `fedora-chromium-config` | We manage browsers ourselves |
| `podman-docker` | We install real Docker |
| `yelp` | GNOME help viewer |

---

## Services Enabled (`17-cleanup.sh`)

### Keep

| Service | Function |
|---|---|
| `brew-setup.service` | Homebrew first-run setup |
| `ublue-user-setup.service` | User-level ublue config |
| `ublue-system-setup.service` | System-level ublue config |
| `tailscaled.service` | Tailscale daemon |
| `uupd.timer` | Automatic system updates |
| `flatpak-nuke-fedora.service` | Removes Fedora Flatpak remote, adds Flathub |
| `flatpak-preinstall.service` | Pre-installs Flathub packages |
| `podman-auto-update.timer` | Auto-update podman containers |
| `rpm-ostree-countme.service` | Fedora countme |
| `input-remapper.service` | Input device remapping |

### Skip

| Service | Reason |
|---|---|
| `dconf-update.service` | GNOME dconf — not applicable to COSMIC |

### Disable

| Service | Reason |
|---|---|
| `rpm-ostreed-automatic.timer` | Replaced by `uupd.timer` |
| `flatpak-add-fedora-repos.service` | We use Flathub |

---

## System Files

### Keep (desktop-agnostic)

| Path | Function |
|---|---|
| `system_files/shared/etc/` | ublue-os configs, brew-setup, Flathub setup |
| `system_files/shared/usr/` | ublue-os scripts and binaries |

### Skip (GNOME-specific)

| Path | Function |
|---|---|
| GNOME extensions from projectbluefin/common | Extensions, gschema, dconf |
| GNOME theming from projectbluefin/common | adw-gtk3 theme, fonts |
| GNOME Software config | GPT scripts for GNOME Software |

---

## Kernel

**Keep**: Signed custom kernel from `ghcr.io/ublue-os/akmods` with akmods support and `v4l2loopback`. This replaces the stock Fedora kernel.

**Note**: The kernel swap is the riskiest part of the build. The FCA kernel may differ from Silverblue's. Test `03-install-kernel-akmods.sh` against `cosmic-atomic:44` first — if it fails, fall back to stock FCA kernel + akmods only.

---

## FCA Baseline (already present — don't duplicate)

From `fca/common.yaml` and `fca/packages/cosmic-atomic.yaml`:

- `podman`, `buildah`, `skopeo`
- `firewalld`, `NetworkManager`, `systemd`
- `mesa-dri-drivers`, `mesa-va-drivers`, `mesa-vdpau-drivers`
- `pipewire*`, `wireplumber`
- `gnome-keyring-pam` (critical for secrets)
- `xdg-desktop-portal-gtk`
- `plymouth`
- `cosmic-session`, `cosmic-edit`, `cosmic-files`, `cosmic-term`, `cosmic-store`, `cosmic-player`, `cosmic-initial-setup`

---

## COSMIC-Specific Needs

| Item | Status | Action |
|---|---|---|
| Keyring/wallet persistence | FCA has `gnome-keyring-pam` | Verify PAM is wired; may need `authselect enable-feature with-gnome-keyring` |
| Browser integration (non-Flatpak) | brew install | VS Code via dnf (code repo), browsers via brew |
| COSMIC terminal vs other terms | FCA has `cosmic-term` | Keep it; don't install GNOME terminal alternatives |
