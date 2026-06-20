# Fedora Atomic ↔ Universal Blue Architecture Compatibility

**Date**: 2026-06-20
**Status**: Complete (no blockers)

## Summary

Fedora Atomic images and Universal Blue images are fully compatible at the OCI container and rpm-ostree layer. FCA (Fedora COSMIC Atomic) and Fedora Silverblue are sibling images from the same build infrastructure, differing only in desktop environment. Bluefin builds on Silverblue; we can build on COSMIC the same way. No fundamental incompatibilities exist.

## Architecture

### Fedora Atomic Build Model

Fedora Atomic variants are built from `rpm-ostree` treefiles — YAML manifests that declare packages, repositories, and post-processing. These are assembled by `rpm-ostree compose` (or Pungi in Fedora's Koji infrastructure) into ostree commits and OCI container images.

FCA's manifest chain (`fca/`):

```
cosmic-atomic.yaml
  ├─→ cosmic-atomic-common.yaml
  │     └─→ common.yaml (shared across all Atomic variants)
  │           ├─→ packages/common.yaml
  │           ├─→ bootupd.yaml, initramfs.yaml, sysroot-ro.yaml
  │           ├─→ kernel-install.yaml, composefs.yaml
  │           └─→ fedora.yaml, dnf5.yaml
  └─→ packages/cosmic-atomic.yaml (cosmic-session, cosmic-edit, ...)
```

Published at: `quay.io/fedora-ostree-desktops/cosmic-atomic:<version>`

### Universal Blue Build Model

UBlue uses a **Containerfile** model, starting FROM the official Fedora Atomic OCI image:

```dockerfile
FROM quay.io/fedora-ostree-desktops/silverblue:${FEDORA_MAJOR_VERSION}
# ... adds ublue-os packages, akmods kernel, negativo17 multimedia, Flathub
```

Published at: `ghcr.io/ublue-os/silverblue-main:<version>`

### Bluefin Build Model

Bluefin uses a two-hop derivation:

```dockerfile
FROM ghcr.io/ublue-os/silverblue-main:${FEDORA_MAJOR_VERSION} AS base
# Plus additional OCI layers from:
#   ghcr.io/projectbluefin/common:latest  (shared system_files)
#   ghcr.io/ublue-os/brew:latest         (Homebrew)
```

Bluefin adds: signed custom kernel, fish/zsh, Docker/qemu/libvirt/incus, VS Code, tailscale, Homebrew, Flathub, Starship prompt, dev tooling (dx flavor), GNOME extensions and theming.

## The Chain

```
Fedora treefiles (fca/)
  ├─→ quay.io/fedora-ostree-desktops/cosmic-atomic:44    ← COSMIC (our target base)
  └─→ quay.io/fedora-ostree-desktops/silverblue:44       ← GNOME  (UBlue's base)

ublue-os/main Containerfile
  └─→ FROM silverblue → ghcr.io/ublue-os/silverblue-main:44

ublue-os/bluefin Containerfile
  └─→ FROM ublue silverblue-main → ghcr.io/ublue-os/bluefin:stable
```

FCA and Silverblue are **sibling images** — same build system, same package ecosystem, different DE. Bluefin's entire overlay stack (packages, system_files, services, Homebrew) operates at the rpm-ostree layer, which is identical across all Fedora Atomic variants.

## Our Approach: FROM FCA, Apply Bluefin Overlay

### Keep (desktop-agnostic Bluefin additions)

| Component | Source |
|---|---|
| Signed kernel + akmods | `bluefin/build_files/base/03-install-kernel-akmods.sh` |
| fish, zsh | `bluefin/build_files/base/04-packages.sh` |
| distrobox, Docker, podman-compose | `04-packages.sh` + `dx/00-dx.sh` |
| qemu, libvirt, incus, cockpit-machines | `dx/00-dx.sh` |
| tailscale | `04-packages.sh` |
| ublue-os packages (just, signing, update-services) | inherited from ublue base |
| Flathub setup | `bluefin/build_files/base/17-cleanup.sh` |
| Homebrew | `ghcr.io/ublue-os/brew` layer |
| Starship, fastfetch, glow, atuin | `05-override-install.sh` + `04-packages.sh` |
| VS Code, flatpak-builder, git-svn, android-tools, bpftrace | `dx/00-dx.sh` |
| uupd automatic updater | `17-cleanup.sh` |

### Skip (GNOME-specific Bluefin additions)

| Component | Reason |
|---|---|
| `build-gnome-extensions.sh` | COSMIC doesn't use GNOME Shell extensions |
| gschema/GTK overrides in system_files | GNOME-specific theming |
| GNOME Software integration | COSMIC uses its own store |
| GNOME dconf customizations | COSMIC has its own config system |
| adw-gtk3 theme, GNOME fonts | Not applicable |
| ptyxis terminal | COSMIC has cosmic-term |

### Conflicts to resolve

COSMIC desktop packages (`cosmic-session`, `cosmic-edit`, `cosmic-files`, `cosmic-term`, `cosmic-store`, `cosmic-player`) have no known conflicts with any Bluefin packages. Both sets are rpm-ostree compatible.

## Precedent: m2OS

The m2OS project (`m2Giles/m2os`) already demonstrated this direction — its Containerfile has a `COSMIC` codepath:

```dockerfile
ARG BASE_IMAGE="ghcr.io/ublue-os/bluefin"
FROM ${BASE_IMAGE}:${TAG_VERSION}
# ... layers COSMIC packages onto Bluefin base
```

Our approach inverts this: start from the officially-supported COSMIC image (FCA) and layer the Bluefin developer tooling on top. This satisfies the "supply chain provenance" constraint — our base is an official Fedora spin with guaranteed maintenance cadence.

## Conclusion

**No blockers.** The OCI image format is identical. The rpm-ostree/dnf5 package layer is shared. The Fedora RPM ecosystem is common. The work is removing GNOME assumptions from Bluefin's build scripts and system_files, then applying the desktop-agnostic developer tooling to an FCA base.
