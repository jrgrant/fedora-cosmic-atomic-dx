# Changelog

## 2026-08-02 — Reflection Constraints Encoded

- HARNESS.md: added "Research notes require adversarial review" constraint (agent, harness-enforcer, pr scope)
- HARNESS.md: rule text includes `Research:` frontmatter citation convention and `origin:` field for mode matching
- skills: added `origin: technical-researcher` and `origin: codebase-analyst` to research note output formats
- docs/research/vscode-install-strategy.md: retrofitted YAML frontmatter with `origin` field
- Slicing record: `encode-reflection-constraints` with S1 (local build gate) and S2 (ujust collision check) filed as issues #40 and #41
- Objection records: spec-mode (`research-review-gate.md`) and code-mode (`research-review-gate-code.md`)

## 2026-08-02 — Research Pipeline Architecture

- New agent: `codebase-analyst` — internal research (workspace only, no web tools)
- New agent: `technical-researcher` — external research (web only, no codebase tools)
- New agent: `research-reviewer` — adversarial review, two modes (external/codebase)
- New skill: `codebase-analysis` — four-phase loop: scope → map → inspect → report
- New skill: `technical-research` — five-phase loop: frame → search → evaluate → synthesise → gap-check, with Phase 6 adversarial review
- ADR: split research architecture with context isolation (`docs/superpowers/adr/2026-08-02-split-research-architecture.md`)
- MODEL_ROUTING.md: routing table and token budget for all three agents
- AGENTS.md: context-isolated dispatch pattern + research architecture decision

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
