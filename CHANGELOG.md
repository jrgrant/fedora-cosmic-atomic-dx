# Changelog

## 2026-08-02 — S1+S2+S4+S8: Akmods FROM Stages, COSMIC Bus Factor, Vendored Homebrew, Dead Repo Cleanup

- Switched akmods RPM acquisition from `skopeo copy` at build time to `FROM`-based build stages with digest pins in the Containerfile, matching the upstream ublue pattern and eliminating network fetches during the install step (#55)
- Documented bus factor risk for the COSMIC COPR (single maintainer: adil192) with upstream-negotiation mitigation notes, and fixed silent `dnf upgrade` failure that was masking COPR upgrade errors with `|| true` (#56)
- Vendored the Homebrew installer script into the repo, switching `brew-setup` from a `curl | bash` remote fetch to a local copy, eliminating an external-network dependency at image build time (#57)
- Removed dead `vscode.repo` from the allowed-repos list in `validate-repos.sh` — VS Code is now installed via brew cask, not an external RPM repo (#58)

## 2026-08-02 — Nightly Build Pivot

- Pivoted CI from daily cron (6am UTC) to nightly (2am UTC) with a check-schedule job that skips the build when HEAD hasn't changed since the last successful run; push, PR, and dispatch events continue to build unconditionally (#62)

## 2026-08-02 — S3+S5: Upstream Dependency Catalog — COPR/Docker Retry Loops and Cosign CI

- Added 3x retry loop to `copr_install_isolated` in copr-helpers.sh following the Tailscale pattern, with explicit error on exhaustion (#60)
- Added 3x retry loop to Docker CE repo fetch in dx/00-dx.sh with explicit error after retry exhaustion (#60)
- Added explicit cosign installation step (`sigstore/cosign-installer@v3`) to CI workflow; fixed test glob from `us*.bats` to `*.bats` so all test files run (#60)
- Added 6 structural bats tests for S3 retry loops and 3 structural bats tests for S5 cosign CI (#60)
- Code-mode adversarial review: 5/5 objections accepted, no blocking issues (#60)

## 2026-08-02 — S6: Justfile Consolidation and Browser Install Mechanism

- Consolidated divergent justfiles: archived the dead rpm2cpio/~/.opt bootstrap path (`justfiles/fedora-cosmic-atomic-dx.just`) to `docs/archive/` with a deprecation header, leaving `60-custom.just` as the single active justfile (#54)
- Switched Flatpak browser installs (Chrome, Brave) to log per-app success/failure instead of silently suppressing errors, and added Flathub remote verification before attempting installs (#54)
- Migrated VS Code install from Flatpak to brew cask for proper desktop integration and credential persistence, and updated `fca-info` and `rebase-helper` recipes accordingly (#54)
- 17 Bats structural tests for justfile consolidation covering archive presence, install mechanisms, error logging, keyring fix verification, and Flathub guard (#54)

## 2026-08-02 — Submodule Recommendations Implemented

- Removed m2os git submodule — not consumed at build time, only referenced for comparison diffs; replaced with explicit document references (R1)
- Added adaptations.yaml as a bill-of-materials for all adapted files, with source provenance, adaptation summary, and last-verified-sync date per entry (R2)
- Build CI now resolves base and brew image tags to OCI content digests via `podman image inspect`, passes digests as build args, and guards against empty-digest propagation (R3)
- HARNESS.md: added Lifecycle column to the submodule table so readers can distinguish build-time dependencies from reference-only repos (R4)
- ADR: flat submodule structure — all submodules at repo root with justification for why hierarchical nesting was rejected (R5)
- 19 Bats tests for submodule recommendations (us7), all passing

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
