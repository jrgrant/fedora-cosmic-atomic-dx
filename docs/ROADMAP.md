# Roadmap: FCA Developer Experience

**Date**: 2026-06-20
**Target**: Fedora COSMIC Atomic + Bluefin developer tooling as a custom OCI image

---

## Phase 0 — Foundation (current)

- [x] PROBLEM.md — problem statement
- [x] Reference repos as submodules (m2os, ublue-os/main, ublue-os/bluefin, fca)
- [x] AI Literacy harness (CLAUDE.md, AGENTS.md, HARNESS.md, agents, CI scaffold)
- [x] Constraint tools installed (shellcheck, gitleaks, yamllint, markdownlint-cli2)
- [x] Research: Fedora Atomic ↔ UBlue compatibility

---

## Phase 1 — Diff the Gap

Goal: know exactly what Bluefin dx has that FCA doesn't, and what we need to adapt.

1. **Map Bluefin's dx packages** — produce a clean list from `bluefin/build_files/dx/00-dx.sh` and `bluefin/build_files/base/04-packages.sh`, categorised by function (container, virtualisation, networking, shell, media, dev tooling)
2. **Map Bluefin's system_files** — identify which are desktop-agnostic (Flathub setup, ublue-os configs, brew setup, dconf update) vs GNOME-specific (extensions, themes, gschema)
3. **Map Bluefin's services** — which systemd units get enabled (`17-cleanup.sh`) and which apply to COSMIC
4. **Identify FCA baseline** — what FCA already has (podman, buildah, skopeo, gnome-keyring-pam, firewalld) so we don't duplicate
5. **Identify COSMIC-specific needs** — keyring/wallet persistence, any missing COSMIC packages we need

**Output**: `docs/research/bluefin-dx-inventory.md`

---

## Phase 2 — Containerfile (MVP)

Goal: a working Containerfile that builds a bootable FCA+Bluefin dx image.

1. **Write Containerfile** — `FROM quay.io/fedora-ostree-desktops/cosmic-atomic:44`
2. **Port Bluefin build scripts** — strip GNOME-only parts, keep desktop-agnostic additions
3. **Layer Homebrew** — import `ghcr.io/ublue-os/brew` layer
4. **Layer Flathub** — replace Fedora Flatpak remote, add `flatpak-nuke-fedora.service`
5. **Enable services** — brew-setup, dconf-update, uupd.timer, tailscaled
6. **Secrets hardening** — verify gnome-keyring-pam is wired correctly for COSMIC
7. **Local build test** — `podman build .` and inspect

**Output**: `Containerfile` + `build_files/` + `system_files/`

---

## Phase 3 — CI Pipeline

Goal: automated rebuilds when FCA publishes new images.

1. **GitHub Actions workflow** — watches `quay.io/fedora-ostree-desktops/cosmic-atomic` for new tags
2. **Build + push** — builds Containerfile, pushes to `ghcr.io/jrgrant/atomic-cosmic`
3. **Smoke tests** — verify key packages present, systemd services enabled, bootc lint
4. **Version tagging** — track FCA version (e.g. `:44`, `:44-20260620`, `:latest`)

**Output**: `.github/workflows/build.yml`

---

## Phase 4 — Bootstrap Script

Goal: user-level setup that doesn't belong in the image.

1. **Homebrew taps** — Bluefin's custom recipes
2. **Justfiles** — `ujust` recipes from Bluefin
3. **Starship init** — shell prompt configuration
4. **Distrobox preset** — a curated dev container
5. **Idempotent** — safe to re-run, survives reboots

**Output**: `scripts/bootstrap.sh`

---

## Phase 5 — Dogfood & Harden

Goal: install on your own machine, fix what breaks.

1. **Install** — `bootc switch ghcr.io/jrgrant/atomic-cosmic:latest`
2. **Verify** — browsers, VS Code, Docker, secrets persistence, dev tooling
3. **Iterate** — fix package conflicts, missing services, COSMIC integration issues
4. **Document** — install instructions in README

---

## Phase 6 — Maintain

Goal: keep it running with minimal ongoing effort.

1. **Watch FCA releases** — CI auto-rebuilds, alerts on build failure
2. **Watch Bluefin dx changes** — periodic diff of bluefin submodule for new tooling
3. **Quarterly audit** — `/harness-audit` to verify constraints still enforced
4. **Upstream when possible** — if COSMIC keyring or dev tooling issues get fixed upstream, adapt

---

## What we don't do

- We don't maintain our own package repo — all packages come from Fedora, UBlue, or Homebrew
- We don't fork Bluefin — we reference it, diff it, and apply what we need to FCA
- We don't support multiple desktop environments — COSMIC only. This is a personal project, not a product
