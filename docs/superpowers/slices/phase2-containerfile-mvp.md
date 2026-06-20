---
task: Phase 2 — Containerfile MVP — FCA + Bluefin dx overlay
task_slug: phase2-containerfile-mvp
date: 2026-06-20
carpaccio_model: deepseek-v4-pro
inseparable: true
progressed_slice: S1
slices:
  - id: S1
    title: FCA+Bluefin Containerfile MVP
    scope: Write the Containerfile, adapted build scripts, and COSMIC-appropriate system_files that layer Bluefin's developer tooling onto quay.io/fedora-ostree-desktops/cosmic-atomic:44. Strip GNOME-specific parts. Include kernel swap, package installation, Homebrew/Flathub setup, service enablement, and secrets hardening.
    decision_focus: Which Bluefin build scripts and system_files to include, adapt, or skip for COSMIC compatibility.
    lens_used: inseparability
    disposition: accepted
    disposition_rationale: Single deliverable — Containerfile and all build scripts must land together for a buildable artefact.
    file_as_issue: false
    issue_url: null
    merged_into: null
---

## S1 — FCA+Bluefin Containerfile MVP — inseparability

### Context

Phase 2 of the FCA Developer Experience project. The research (docs/research/fedora-atomic-ublue-compatibility.md) confirms Fedora Atomic images and Universal Blue images are fully compatible at the OCI container layer. The dx inventory (docs/research/bluefin-dx-inventory.md) maps every Bluefin package, service, and system file, categorising what to keep, skip, or review for COSMIC compatibility.

This slice produces the Containerfile and all supporting build infrastructure needed to build a bootable OCI image. It cannot be split because the Containerfile references build_files/, which references system_files/ — all must land together for a buildable artefact. A partial slice would produce a non-building, non-verifiable commit.

### Decision content

1. Write Containerfile with `FROM quay.io/fedora-ostree-desktops/cosmic-atomic:44`
2. Adapt `build_files/shared/build.sh` — the build orchestrator that sequences all steps
3. Adapt `build_files/base/03-install-kernel-akmods.sh` — kernel swap with ublue-os/akmods
4. Adapt `build_files/base/04-packages.sh` — base packages, GNOME parts stripped
5. Adapt `build_files/dx/00-dx.sh` — developer packages (Docker, qemu, VS Code, etc.)
6. Adapt `build_files/base/17-cleanup.sh` — systemd service enablement, GNOME services stripped
7. Adapt `build_files/base/00-image-info.sh` — image identity metadata
8. Copy `build_files/shared/copr-helpers.sh` — COPR installation helpers (unchanged)
9. Adapt `system_files/shared/` — COSMIC-appropriate subset of ublue-os config files
10. Omit `build-gnome-extensions.sh` entirely — not applicable to COSMIC

### Dependencies

All sources are in the reference submodules:
- `bluefin/build_files/` — build scripts
- `bluefin/system_files/` — system configuration files
- `bluefin/Containerfile` — Containerfile template

Outputs from previous phases:
- `docs/research/bluefin-dx-inventory.md` — what to keep/skip

### Rationale

Single-slice inseparability: the Containerfile RUN command calls build.sh which calls all sub-scripts. A commit adding the Containerfile without all referenced scripts would fail `podman build`. Splitting would produce non-verifiable intermediate states, violating the "evidenced process" constraint.

---

## Sequencing recommendation

Any order — single slice, inseparable.

---

## Explicitly not slicing on

- **CI pipeline** (Phase 3) — separate deliverable, no dependency on Containerfile content
- **Bootstrap script** (Phase 4) — separate deliverable, post-install concern
- **Cosign key generation** — can be done independently
- **README / install docs** — separate documentation deliverable
- **FCA baseline inventory** — already covered by dx-inventory.md research
