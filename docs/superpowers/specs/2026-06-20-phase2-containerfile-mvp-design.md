# FCA+Bluefin Containerfile MVP — Design Spec

**Date**: 2026-06-20
**Status**: draft
**Branch**: phase2-containerfile-mvp
**Issue**: #1

## 1. Problem

Fedora COSMIC Atomic lacks Bluefin's developer tooling. The research
(docs/research/fedora-atomic-ublue-compatibility.md) confirms FCA and
UBlue are OCI-compatible. The dx inventory (docs/research/bluefin-dx-inventory.md)
maps exactly what to port. We need a Containerfile and supporting build
infrastructure that layers Bluefin's desktop-agnostic developer tooling
onto FCA as a bootable OCI image.

## 2. Scope

This spec covers the Containerfile, adapted build scripts, and COSMIC-appropriate
system_files. It does NOT cover CI pipeline (Phase 3), bootstrap script (Phase 4),
or installation documentation.

## 3. Design

### 3.1 Image chain

```
quay.io/fedora-ostree-desktops/cosmic-atomic:44
  └─→ Custom kernel (ghcr.io/ublue-os/akmods)
  └─→ Base packages (fish, zsh, tailscale, etc. — GNOME stripped)
  └─→ DX packages (Docker, qemu, libvirt, VS Code, etc.)
  └─→ Homebrew OCI layer (ghcr.io/ublue-os/brew)
  └─→ Flathub setup (replace Fedora Flatpak)
  └─→ ublue-os services (brew-setup, uupd.timer, tailscaled)
  └─→ Image identity (ID=atomic-cosmic, VENDOR=jrgrant)
  = ghcr.io/jrgrant/atomic-cosmic:latest
```

### 3.2 Containerfile structure

```dockerfile
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/cosmic-atomic"
ARG FEDORA_MAJOR_VERSION="44"
ARG BREW_IMAGE="ghcr.io/ublue-os/brew:latest"
ARG BREW_IMAGE_SHA=""

FROM ${BREW_IMAGE}@${BREW_IMAGE_SHA} AS brew
FROM scratch AS ctx
COPY /system_files /system_files
COPY /build_files /build_files
COPY --from=brew /system_files /system_files/shared

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/build_files/shared/build.sh
CMD ["/sbin/init"]
RUN bootc container lint
```

Mirrors Bluefin's Containerfile but with:
- FCA base image instead of UBlue silverblue-main
- No projectbluefin/common layer (GNOME theming)
- No GNOME extensions build step
- COSMIC-appropriate image identity

### 3.3 Build scripts

| Script | Source | Changes |
|---|---|---|
| `build_files/shared/build.sh` | bluefin | Strip `build-gnome-extensions.sh` call; add `IMAGE_FLAVOR=dx` always |
| `build_files/base/00-image-info.sh` | bluefin | `ID=atomic-cosmic`, `VENDOR=jrgrant`, `PRETTY_NAME="Atomic COSMIC DX"` |
| `build_files/base/03-install-kernel-akmods.sh` | bluefin | Minimal changes — kernel swap is desktop-agnostic |
| `build_files/base/04-packages.sh` | bluefin | Strip GNOME packages from FEDORA_PACKAGES and EXCLUDED_PACKAGES |
| `build_files/dx/00-dx.sh` | bluefin | Unchanged — all DX packages are desktop-agnostic |
| `build_files/base/17-cleanup.sh` | bluefin | Disable `dconf-update.service`; keep all other services |
| `build_files/shared/copr-helpers.sh` | bluefin/ublue | Copy unchanged |
| `build_files/shared/validate-repos.sh` | bluefin | Copy unchanged |

### 3.4 System files

Adapt `system_files/shared/` from Bluefin. File-by-file inventory:

**Keep (desktop-agnostic):**

| Path | Function |
|---|---|
| `system_files/shared/etc/ublue-os/` | ublue-os system configs |
| `system_files/shared/etc/systemd/system/brew-setup.service` | Homebrew first-run |
| `system_files/shared/etc/systemd/system/ublue-system-setup.service` | System-level ublue setup |
| `system_files/shared/etc/systemd/system/ublue-user-setup.service` | User-level ublue setup |
| `system_files/shared/etc/systemd/system/flatpak-nuke-fedora.service` | Flathub migration |
| `system_files/shared/etc/systemd/system/flatpak-preinstall.service` | Flathub preinstall |
| `system_files/shared/usr/libexec/ublue-os/` | ublue-os scripts |
| `system_files/shared/usr/share/ublue-os/` | ublue-os data |

**Skip (GNOME-specific):**

| Path | Reason |
|---|---|
| `system_files/shared/etc/dconf/` | GNOME dconf profiles |
| `system_files/shared/usr/share/glib-2.0/schemas/*.gschema.override` | GNOME gschema overrides |
| `system_files/shared/etc/systemd/system/dconf-update.service` | GNOME dconf updater |
| `system_files/shared/usr/share/gnome-shell/` | GNOME Shell extensions |
| `system_files/shared/usr/share/themes/` | GNOME theming (adw-gtk3) |
| `system_files/shared/usr/share/fonts/` (GNOME-specific) | GNOME font configs |

**Skip (projectbluefin/common layer — not imported):**

| Path | Reason |
|---|---|
| All files from `ghcr.io/projectbluefin/common` | GNOME theming, icons, dconf, fonts — entire layer skipped |

### 3.5 Packages

Per `docs/research/bluefin-dx-inventory.md`:

**Base packages (04-packages.sh):** fish, zsh, just, fastfetch, glow, gum, bootc, tailscale, iwd, krb5-workstation, samba stack, rclone, restic, borgbackup, tmux, git-credential-libsecret, python3-pip, python3-pygit2, gcc, gcc-c++, make, wireguard-tools, wl-clipboard, waypipe, openssh-askpass, setools-console, jetbrains-mono-fonts-all, adwaita-fonts-all

**DX packages (00-dx.sh):** docker-ce stack, podman-compose/machine/tui, qemu full stack, libvirt/virt-manager/virt-viewer, edk2-ovmf, incus/lxc, cockpit-* stack, VS Code (Microsoft repo), flatpak-builder, git-subtree/svn, android-tools, sysprof, bpftrace/bpfmon, bcc, trace-cmd, udica, iotop/nicstat/tiptop, p7zip, genisoimage, cascadia-code-fonts

**Excluded:** cosign, fedora-bookmarks, fedora-chromium-config, podman-docker, yelp (per dx-inventory)

### 3.6 Services

Enable: brew-setup, ublue-system-setup, ublue-user-setup, tailscaled, uupd.timer, flatpak-nuke-fedora, flatpak-preinstall, podman-auto-update.timer, rpm-ostree-countme, input-remapper

Disable: rpm-ostreed-automatic.timer, flatpak-add-fedora-repos.service

Skip: dconf-update.service (GNOME-specific)

### 3.7 Secrets hardening

FCA ships `gnome-keyring-pam`. Verify the PAM stack is wired correctly for COSMIC. If COSMIC does not start gnome-keyring at session open, add a systemd user service or PAM override to ensure it's available.

## 4. User stories

### US1 — Build a bootable image

**As** the project maintainer
**I want** to run `podman build -t atomic-cosmic .` and get a bootable OCI image
**So that** I can test the overlay locally before pushing to ghcr.io.

Acceptance scenarios:
1. `podman build` completes without error
2. `bootc container lint` passes on the built image
3. `rpm -qa` from the image includes cosmic-session, cosmic-term (FCA base intact)
4. `rpm -qa` from the image includes docker-ce, code, tailscale (DX packages present)
5. `rpm -qa` does NOT include gnome-software, gnome-extensions-app (GNOME stripped)

### US2 — GNOME isolation

**As** a COSMIC user
**I want** the image to exclude GNOME-specific configuration
**So that** no GNOME services or extensions conflict with COSMIC.

Acceptance scenarios:
1. `rpm -qa` does not include gnome-extensions-app, gnome-software, gnome-software-rpm-ostree
2. `systemctl list-unit-files` from the image does not show dconf-update.service as enabled
3. No `.gschema.override` files present under `/usr/share/glib-2.0/schemas/`
4. cosmic-session RPM is present and unmodified from FCA base

### US3 — Developer tooling present

**As** a developer
**I want** Docker, VS Code, distrobox, qemu/libvirt, and tailscale installed
**So that** I have a complete development environment out of the box.

Acceptance scenarios:
1. `rpm -qa` includes docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin, docker-compose-plugin
2. `rpm -qa` includes code (VS Code from Microsoft repo)
3. `rpm -qa` includes distrobox
4. `rpm -qa` includes qemu-system-x86-core, qemu-img, libvirt, virt-manager
5. `rpm -qa` includes tailscale

### US4 — Homebrew and Flathub

**As** a developer
**I want** brew and Flathub configured
**So that** I can install additional CLI and GUI applications without Flatpak sandbox friction.

Acceptance scenarios:
1. `/home/linuxbrew/.linuxbrew/bin/brew` exists (Homebrew binary present)
2. `/etc/flatpak/remotes.d/flathub.flatpakrepo` exists
3. `flatpak-add-fedora-repos.service` is disabled

### US5 — Automatic updates

**As** a system owner
**I want** the image to receive automatic system updates
**So that** I track FCA's release cadence without manual intervention.

Acceptance scenarios:
1. `systemctl list-unit-files` shows uupd.timer as enabled
2. `systemctl list-unit-files` shows rpm-ostreed-automatic.timer as disabled

## 5. Files to create/modify

| File | Action |
|---|---|
| `Containerfile` | Create |
| `build_files/shared/build.sh` | Create (adapted) |
| `build_files/base/00-image-info.sh` | Create (adapted) |
| `build_files/base/03-install-kernel-akmods.sh` | Create (adapted) |
| `build_files/base/04-packages.sh` | Create (adapted, GNOME stripped) |
| `build_files/base/17-cleanup.sh` | Create (adapted, GNOME services stripped) |
| `build_files/base/18-workarounds.sh` | Create (copy — currently empty/no-op) |
| `build_files/base/19-initramfs.sh` | Create (copy) |
| `build_files/dx/00-dx.sh` | Create (adapted) |
| `build_files/shared/copr-helpers.sh` | Create (copy from bluefin) |
| `build_files/shared/validate-repos.sh` | Create (copy from bluefin) |
| `system_files/shared/etc/` | Create (adapted, GNOME stripped) |
| `system_files/shared/usr/` | Create (adapted, GNOME stripped) |

## 6. Exclusions

- CI pipeline (Phase 3)
- Bootstrap script (Phase 4)
- Cosign signing key generation
- README / install docs
- Container push to ghcr.io
