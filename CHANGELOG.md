# Changelog

## 2026-06-20 — Phase 2: Containerfile MVP

- Containerfile: FROM quay.io/fedora-ostree-desktops/cosmic-atomic:44 with Bluefin dx overlay
- build_files/: 13 build scripts adapted from Bluefin (GNOME stripped for COSMIC)
- system_files/: ublue-os services (brew-setup, flatpak-nuke-fedora, flathub preinstall)
- tests/: 41 bats structural verification tests
- docs/: Design spec, slicing record, spec-mode and code-mode objection records, choice stories
- brew-setup.service: Restart=on-failure + RestartSec=30 to survive transient network failures at first boot
