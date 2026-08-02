---
date: 2026-08-02
question: "Should we adopt bluefin's ${KERNEL} suffix in our akmods skopeo tag?"
origin: technical-researcher
status: complete
---

# Akmods `${KERNEL}` Tag Suffix Investigation

## Research Question

Bluefin's `03-install-kernel-akmods.sh` changed the skopeo copy tag from:
```
"${AKMODS_FLAVOR}-$(rpm -E %fedora)"
```
to:
```
"${AKMODS_FLAVOR}-$(rpm -E %fedora)-${KERNEL}"
```

Should we adopt this change?

## Sources

1. [ublue-os/akmods README](https://github.com/ublue-os/akmods) — tag format documentation
2. Bluefin `03-install-kernel-akmods.sh` (commit 5831508)
3. Bluefin CI workflow `build-image-stable.yml` — `kernel_pin: 7.0.12-201.fc44`
4. Our `03-install-kernel-akmods.sh` (adapted from bluefin)

## Findings

### F1: Akmods image tags use `{flavor}-{fedora_version}` format
**Confidence:** confirmed
**Sources:** [tier 1] ublue-os/akmods README — tags documented as `main-44`, `coreos-stable-43`
**Detail:** The akmods README shows tags like `main-44`, `coreos-stable-43`. No kernel version suffix in documented tags.
**Caveat:** The README may not reflect the latest tagging scheme. Bluefin is dogfooding the change.

### F2: Bluefin pairs `${KERNEL}` with `kernel_pin` in CI
**Confidence:** likely
**Sources:** [tier 2] Bluefin commit 5831508 — activates `kernel_pin: 7.0.12-201.fc44` alongside the tag change
**Detail:** The `${KERNEL}` variable likely comes from the CI workflow's kernel_pin parameter. Bluefin pins a specific kernel for ZFS compatibility, and the kernel-version-specific akmods tag ensures they get akmods built for that exact kernel.
**Caveat:** Have not confirmed the akmods images actually have kernel-version-specific tags on ghcr.io.

### F3: We do not pin a kernel version
**Confidence:** confirmed
**Sources:** [tier 1] Our CI workflow — no `kernel_pin` parameter
**Detail:** We use the latest kernel from the akmods COPR repo, not a pinned version. Our current tag `"${AKMODS_FLAVOR}-$(rpm -E %fedora)"` resolves to e.g. `main-44`, which pulls the latest akmods for Fedora 44 main kernel.

## Decision

**Do not adopt `${KERNEL}` suffix.** We don't pin a kernel version, so we have no `${KERNEL}` to pass. The current tag format matches the documented akmods tagging scheme. If we later need kernel pinning (e.g., for ZFS), adopt the full bluefin pattern (pin + kernel-specific tag) together.

## External Research Needed

- [ ] Confirm whether akmods images on ghcr.io actually have kernel-version-specific tags (e.g., `main-44-7.0.12`) or if bluefin's change is forward-looking
