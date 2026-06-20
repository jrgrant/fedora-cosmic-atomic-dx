---
spec: docs/superpowers/specs/2026-06-20-phase2-containerfile-mvp-design.md
date: 2026-06-20
cartographer_model: deepseek-v4-pro
stories:
  - id: "#1"
    title: FCA as base (not UBlue intermediate)
    context: The Containerfile uses `FROM quay.io/fedora-ostree-desktops/cosmic-atomic:44` directly rather than going through `ghcr.io/ublue-os/silverblue-main`. This bypasses UBlue's base reprocessing step.
    alternatives_considered:
      - "FROM ghcr.io/ublue-os/silverblue-main → then swap GNOME for COSMIC (the m2OS pattern)"
      - "FROM quay.io/fedora-ostree-desktops/cosmic-atomic:44 directly (chosen)"
    rationale: Direct FCA satisfies the supply chain provenance constraint — the base is an official Fedora spin. Going through UBlue's silverblue-main would then require removing GNOME, which is more work and introduces an unnecessary intermediate. Bluefin itself is moving toward direct Fedora FROM (projectbluefin/bluefin's Containerfile already uses direct silverblue FROM for some builds per THEPATTERN.md).
    disposition: accepted
    disposition_rationale: null
  - id: "#2"
    title: Kernel swap retained despite risk
    context: The ublue-os/akmods kernel swap replaces the stock Fedora kernel with a signed custom kernel with akmods support and v4l2loopback. The diaboli objected that FCA's kernel might differ from Silverblue's (O1).
    alternatives_considered:
      - "Keep stock FCA kernel, skip akmods (rejected — loses v4l2loopback, akmods, and signed kernel)"
      - "Swap kernel from ublue-os/akmods (chosen)"
    rationale: FCA and Silverblue use identical kernel packages from common.yaml. The akmods kernel version is dynamically labelled, not desktop-specific. The risk was investigated and found to be a non-issue. O1 deferred.
    disposition: accepted
    disposition_rationale: null
  - id: "#3"
    title: GNOME stripped at package and service level, not at build-script level
    context: Rather than forking Bluefin's build scripts to add COSMIC conditionals, we adapt the package lists and service enablement lines directly — removing GNOME packages from FEDORA_PACKAGES, removing GNOME services from systemctl enable calls, and removing GNOME config from system_files.
    alternatives_considered:
      - "Add COSMIC codepath to Bluefin scripts (rejected — maintenance burden, upstream divergence)"
      - "Adapt package lists and service lines directly (chosen)"
    rationale: The adaptation surface is small and well-defined: package arrays, systemctl enable lines, and file exclusions. A codepath-based approach would require ongoing diff maintenance against upstream Bluefin. Direct adaptation means we diff once, adapt once, and maintain independently.
    disposition: accepted
    disposition_rationale: null
  - id: "#4"
    title: IMAGE_FLAVOR=dx always — no base-first intermediate
    context: The diaboli suggested a non-dx base image first (O5). The spec locks dx always.
    alternatives_considered:
      - "Build base (non-dx) first, then dx overlay (rejected)"
      - "Build dx from the start (chosen)"
    rationale: The whole point of this project is developer tooling. Docker, qemu, VS Code ARE the value proposition. Building base-first would double the work for no risk reduction — if the dx layer has issues, we debug them in context rather than pretending a base-only image validates anything useful. O5 rejected.
    disposition: accepted
    disposition_rationale: null
  - id: "#5"
    title: Homebrew as OCI layer import, not dnf-installed
    context: The Containerfile imports `ghcr.io/ublue-os/brew` as a separate FROM stage, rather than installing brew via dnf or a script. This matches Bluefin's pattern.
    alternatives_considered:
      - "Install brew via script in build.sh (rejected — duplicates UBlue's maintained brew image)"
      - "Import ghcr.io/ublue-os/brew as OCI layer (chosen)"
    rationale: The UBlue brew image is independently maintained and versioned. Importing it as a layer means we get brew updates without touching our Containerfile. The diaboli's O4 correctly noted we should pin the digest — accepted and will be fixed.
    disposition: accepted
    disposition_rationale: null
  - id: "#6"
    title: Build-time acceptance criteria, not runtime
    context: The original spec had acceptance scenarios requiring a booted system (US1-US5). The diaboli noted these can't be verified within scope (O3).
    alternatives_considered:
      - "Keep runtime acceptance scenarios, defer verification to Phase 5 (rejected — misleading to have unverifiable acceptance in the spec)"
      - "Rescope acceptance to build-time verification (chosen)"
    rationale: The spec should only assert what can be verified within its scope. Build-time checks (bootc lint, rpm -qa, systemctl list-unit-files in the image) are verifiable. Runtime behavior belongs in Phase 5 dogfood acceptance. O3 accepted.
    disposition: accepted
    disposition_rationale: null

---

## Cross-references resolved

- O1 → story #2 (kernel swap retained, risk investigated and dismissed)
- O2 → spec §3.4.1 (system_files inventory to be added)
- O3 → story #6 (acceptance rescoped to build-time)
- O4 → story #5 (brew digest pin)
- O5 → story #4 (dx always)
- O6 → no story (deferred — reactive fix if needed)

## Unresolved

None — all 6 diaboli objections mapped to dispositions.
