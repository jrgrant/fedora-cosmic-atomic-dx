# Changelog

## 2026-07-17 — Phase 6: Bootstrap fixes, CI re-enabled, README

- COSMIC keyring fixes: portal `UseIn=COSMIC`, autostart `OnlyShowIn=COSMIC`, D-Bus activation env for gcr-prompter
- COSMIC 1.3.0 upgrade via adil192 COPR
- Bootstrap switch to Flatpak (Chrome, Brave, VS Code) — no more `~/.opt` hack installs
- Tailscale repo retry for upstream 504 errors
- rpm-ostree rebase by explicit digest (avoids "Old and new refs are equal")
- CI: re-enable scheduled builds (daily 0600 UTC) and push-to-main trigger
- README: install instructions, what's included, local build guide
- Submodules bumped to latest upstream (bluefin, m2os, ublue; fca unchanged)
- AGENTS.md: ujust path, recipe collision, circular delegation, atomic filesystem gotchas
- REFLECTION_LOG.md: post-build validation and keyring cycle reflections

## 2026-06-20 — Phase 2: Containerfile MVP

- Containerfile: FROM quay.io/fedora-ostree-desktops/cosmic-atomic:44 with Bluefin dx overlay
- build_files/: 13 build scripts adapted from Bluefin (GNOME stripped for COSMIC)
- system_files/: ublue-os services (brew-setup, flatpak-nuke-fedora, flathub preinstall)
- tests/: 41 bats structural verification tests
- docs/: Design spec, slicing record, spec-mode and code-mode objection records, choice stories
- brew-setup.service: Restart=on-failure + RestartSec=30 to survive transient network failures at first boot
