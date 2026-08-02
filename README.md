# Fedora COSMIC Atomic DX

A custom OCI image that layers [Bluefin](https://github.com/ublue-os/bluefin)'s
curated developer tooling onto [Fedora COSMIC Atomic](https://forge.fedoraproject.org/atomic-desktops/config) —
COSMIC desktop, no GNOME, fully maintained by Fedora upstream.

Read [PROBLEM.md](PROBLEM.md) for the backstory. See [ROADMAP.md](docs/ROADMAP.md)
for current status.

## What's included

- **Bluefin developer tooling**: Homebrew with bluefin taps, `ujust` justfiles,
  distrobox integration, starship prompt
- **NVIDIA drivers**: kernel-akmods with nvidia-open from ublue-os
- **COSMIC 1.3.0**: upgraded via adil192 COPR (ahead of stock F44)
- **Keyring fixes**: XDG Desktop Portal secrets wired for COSMIC
- **Flatpak user apps**: Chrome, Brave, VS Code installed via `ujust bootstrap`
  (no more `~/.opt` hacks — Flatpak handles desktop integration, updates, and
  portal-based secrets when `oo7` lands)
- **Dev mode**: mutable system-state escape hatch for packages and toolchains
  without rpm-ostree layering

## Install

### Prerequisites

You must already be running Fedora COSMIC Atomic (F44). If you are on another
Atomic variant, rebase to the base image first:

```bash
rpm-ostree rebase ostree-unverified-registry:quay.io/fedora-ostree-desktops/cosmic-atomic:44
```

Reboot, then install this image:

### Rebase to this image

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jrgrant/fedora-cosmic-atomic-dx-nvidia:44
sudo systemctl reboot
```

> **Note**: rpm-ostree resolves tags at rebase time. If you are already on this
> image and rebuilding with the same tag, use a digest-based rebase instead:
> `rpm-ostree rebase ostree-unverified-registry:ghcr.io/jrgrant/fedora-cosmic-atomic-dx-nvidia:44@sha256:<digest>`

### Bootstrap

After rebooting into the new image, run the bootstrap recipe:

```bash
ujust bootstrap
```

This installs Homebrew, starship, distrobox, Flatpak user apps (Chrome, Brave,
VS Code), and configures your environment. Run `ujust` with no arguments to see
all available recipes.

## Build locally

```bash
git clone --recurse-submodules https://github.com/jrgrant/fedora-cosmic-atomic-dx.git
cd fedora-cosmic-atomic-dx
just build
```

To build and immediately rebase your running system:

```bash
just install
```

## Verify

Structural and build-validation tests run in CI on every PR. To run them locally:

```bash
just test
```

## License

This project's original content is MIT. Submodules (m2os, bluefin, ublue, fca)
carry their own licenses — see each submodule's root for details.
