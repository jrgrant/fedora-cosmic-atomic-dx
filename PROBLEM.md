# Project: m2OS Developer Experience

## Problem Statement

[m2OS](https://github.com/m2Giles/m2os) is a community OCI image built on [Bluefin](https://github.com/ublue-os/bluefin)/[Universal Blue](https://github.com/ublue-os/main) that replaces GNOME with the COSMIC desktop environment. It is maintained as a side-project by a single Bluefin contributor. Fedora COSMIC Atomic — the official Fedora spin with COSMIC — is a separate, well-supported project; this problem statement is about **m2OS specifically**.

m2OS occupies an awkward gap between two well-supported options and suffers from neglect. The user's motivation for choosing m2OS is straightforward: Bluefin's curated developer tooling, automation, and quality-of-life features are best-in-class, but Bluefin ships GNOME — a desktop the user does not want to use. m2OS promised the best of both worlds: Bluefin's developer experience with COSMIC as the desktop. In practice, m2OS does not port all of Bluefin's developer tooling and features, and what is present suffers from the maintenance gap. The user is therefore migrating to [Fedora COSMIC Atomic](https://forge.fedoraproject.org/atomic-desktops/config) (FCA) — the official Fedora spin — for stability and regular updates. However, FCA is a stock Fedora Atomic image and does not include any of Bluefin's curated developer tooling.

While FCA solves the stability and maintenance problem, it is a stock Fedora Atomic image — none of Bluefin's developer tooling is present. The gaps are:

1. **No dev mode** — stock Fedora Atomic has no equivalent of Bluefin's dev mode. Without it, any system-level package or configuration requires either a full rpm-ostree layer (and reboot) or a containerized workaround. There is no supported mutable escape hatch.

2. **Flatpak-only applications** — FCA, like most Atomic desktops, defaults to Flatpak for GUI applications. Key developer apps (browsers, VS Code, terminals) are sandboxed, introducing friction around host filesystem access, IPC, peripheral access, password manager integration, and extension tooling. There is no built-in path for native application installation that survives image updates and integrates cleanly with the COSMIC desktop.

3. **No Bluefin CLI tooling** — FCA lacks Bluefin's curated CLI stack: the Bluefin Homebrew tap with their custom recipes, justfiles (`ujust`), distrobox presets, and other developer quality-of-life automation.

4. **Secrets management uncertainty** — keyring/wallet persistence may be unreliable (as it was on m2OS, whether due to missing PAM integration, COSMIC keyring immaturity, or both). This needs to be verified and hardened on FCA.

## Goal

Create a reliable, repeatable, easily maintainable bootstrap process that layers three Bluefin subsystems onto a stable Fedora COSMIC Atomic base:

1. **Bluefin dev mode** — the ability to install and manage mutable system-level packages, kernel modules, and toolchains outside of rpm-ostree layering, giving developers an escape hatch from immutability without sacrificing image-based updates.

2. **Bluefin apps** — native (non-Flatpak, non-rpm-ostree) installation of key developer applications — browsers, VS Code, terminals — with proper desktop environment integration, filesystem access, and IPC, avoiding Flatpak sandbox friction.

3. **Bluefin CLI** — the curated command-line developer tooling stack, including Bluefin's Linux port of Homebrew with their custom recipes (taps), justfiles, distrobox integration, and other quality-of-life automation.

The result: Bluefin-quality developer experience on COSMIC, without GNOME and without an under-maintained community image.
