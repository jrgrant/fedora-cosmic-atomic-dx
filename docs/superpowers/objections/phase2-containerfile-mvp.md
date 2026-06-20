---
spec: docs/superpowers/specs/2026-06-20-phase2-containerfile-mvp-design.md
date: 2026-06-20
mode: spec
diaboli_model: deepseek-v4-pro
objections:
  - id: O1
    category: risk
    severity: high
    claim: The kernel swap from Fedora stock to ublue-os/akmods coreos-stable is the highest-risk operation in the build and is not gated by a testable condition
    evidence: "§3.3: 'Minimal changes — kernel swap is desktop-agnostic.' The spec assumes the FCA kernel and the Silverblue kernel are the same RPM set. They may not be — FCA's treefile (cosmic-atomic-common.yaml) may pull different kernel packages than Silverblue. The ublue-os/akmods kernel is built against Silverblue's kernel. If FCA ships a different kernel version, the akmods modules won't load. The dx-inventory.md note acknowledges this risk ('The kernel swap is the riskiest part') but the spec does not include a fallback or verification gate."
    disposition: deferred
    disposition_rationale: FCA and Silverblue share identical kernel packages from common.yaml (kernel, kernel-modules, kernel-modules-extra). The ublue akmods kernel version is dynamically labelled (ostree.linux), not desktop-specific. The kernel swap is truly desktop-agnostic — verified by reading fca/common.yaml and ublue/Containerfile.
  - id: O2
    category: implementation
    severity: high
    claim: The system_files adaptation is underspecified — the spec says 'Skip: GNOME dconf profiles, GNOME gschema overrides, GNOME extension configs' but does not enumerate which files to keep
    evidence: "§3.4: three 'Keep' items and three 'Skip' items at the category level, but no file-by-file inventory. The bluefin/system_files/shared/ directory contains dozens of files. The build will either fail (if we copy GNOME files that reference missing GNOME packages) or silently carry GNOME config that does nothing — both outcomes violate the spec's US2 acceptance scenarios but are impossible to verify without knowing which files are included."
    disposition: accepted
    disposition_rationale: Spec needs a file-by-file inventory of system_files/shared/ with keep/skip decisions. Will add as §3.4.1.
  - id: O3
    category: specification quality
    severity: medium
    claim: The spec defines acceptance scenarios that can only be verified by booting the image, but the spec scope excludes CI and installation — there is no verification path within scope
    evidence: "US1 through US5 all define 'As a' stories with acceptance scenarios that require a booted system (docker --version, code --version, systemctl status uupd.timer, etc.). The spec's §6 Exclusions list CI pipeline, bootstrap script, and container push. The spec scopes itself to writing files that produce a buildable artefact, but the acceptance criteria demand runtime verification of a booted system. These cannot be satisfied within the spec's own scope boundary."
    disposition: accepted
    disposition_rationale: Acceptance scenarios rescoped to build-time verification (bootc lint, rpm -qa checks on image layers). Runtime scenarios deferred to Phase 5.
  - id: O4
    category: scope
    severity: medium
    claim: The Homebrew layer import (ghcr.io/ublue-os/brew) creates a dependency on an external image that could change independently of this project
    evidence: "§3.2 Containerfile: 'FROM ghcr.io/ublue-os/brew:latest AS brew'. The :latest tag is mutable — upstream changes to that image propagate into our build without our awareness or control. A digest pin would make this deterministic. Bluefin's own Containerfile uses ARG BREW_IMAGE_SHA for this reason. Our spec does not pin a digest."
    disposition: accepted
    disposition_rationale: One-line fix — use BREW_IMAGE_SHA arg with digest pin, matching Bluefin's Containerfile pattern.
  - id: O5
    category: alternatives
    severity: low
    claim: The spec locks IMAGE_FLAVOR=dx always but Phase 2 is the MVP — a non-dx base image might be a more prudent first step
    evidence: "§3.3 build.sh row: 'add IMAGE_FLAVOR=dx always'. The dx packages include Docker daemon, qemu with KVM, libvirt, incus, cockpit, and VS Code — substantial additions that increase build complexity and potential for package conflicts. Building and testing a base (non-dx) image first would de-risk the kernel swap and base packages before adding the full container/virtualisation stack."
    disposition: rejected
    disposition_rationale: This is a developer-tooling project — dx IS the point. Building base-first would double work with no risk reduction. If the full stack fails, we debug it together rather than in two rounds.
  - id: O6
    category: implementation
    severity: low
    claim: copr-helpers.sh is copied unchanged from Bluefin but Bluefin's helper may reference ublue-os COPRs that expect GNOME packages to be present
    evidence: "§3.3: 'Copy unchanged.' The copr-helpers.sh script likely references ublue-os/packages COPR which includes packages compiled against GNOME libraries (e.g., bazaar). If those packages have GNOME dependencies that we stripped, install will fail or pull GNOME back in transitively. The spec should note that copr helpers may need adaptation for COSMIC."
    disposition: deferred
    disposition_rationale: copr-helpers.sh is a generic isolated-install helper — doesn't hardcode GNOME deps. ublue-os/packages packages (uupd) are desktop-agnostic. If a COPR package pulls GNOME transitively, we'll see it in the build log and can fix reactively.

---

## Explicitly not objecting to

1. **The FCA base image choice** — quay.io/fedora-ostree-desktops/cosmic-atomic is the correct base per the supply-chain constraint; it is official, actively maintained, and the sibling of Silverblue that Bluefin uses.
2. **The build script porting strategy** — adapting Bluefin scripts rather than writing from scratch is sound; it preserves the upstream logic that's been battle-tested in Bluefin CI.
3. **The package selection** — the dx-inventory.md keep/skip categorisation is thorough and well-evidenced against the actual Bluefin source files.
4. **The Flathub replacement** — swapping Fedora Flatpak for Flathub is a standard UBlue pattern and is desktop-agnostic.
5. **The uupd updater** — using Bluefin's uupd rather than rpm-ostreed-automatic is a deliberate choice that matches Bluefin's update model and is documented in the upstream.
6. **The COSMIC desktop preservation** — the spec correctly treats COSMIC packages as inherited from the base and not to be modified or removed.
