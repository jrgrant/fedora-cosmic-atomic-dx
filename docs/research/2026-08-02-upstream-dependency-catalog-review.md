---
date: 2026-08-02
target: docs/research/2026-08-02-upstream-dependency-catalog.md
mode: codebase
reviewer: Explore subagent (independent context)
origin: research-reviewer (delegated via Explore agent)
objections:
  - id: O1
    category: missed-counterexample
    severity: critical
    claim: "F1/R1 recommends building akmods digest-pinning — but ublue/Containerfile:8-19 and ublue/Justfile:165-166 already implement this pattern"
    evidence: "ublue submodule has AKMODS_DIGEST/AKMODS_NVIDIA_DIGEST ARGs with Null Object pattern, and Justfile resolves digests from image-versions.yaml. The analyst only checked the project root Containerfile."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
  - id: O2
    category: missed-counterexample
    severity: high
    claim: "_copr_ublue-os-akmods.repo is miscategorised as 'cosmetic' — it's conditionally enabled during kernel install at 03-install-kernel-akmods.sh:40-41"
    evidence: "The COPR has a three-phase build lifecycle: pre-installed in base image, conditionally enabled during kernel install, disabled at cleanup. Not purely cosmetic."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
  - id: O3
    category: code-evidence-mismatch
    severity: high
    claim: "F7 claims recipe name collision between justfiles — but recipe names are different (fca-bootstrap vs bootstrap, fca-info vs info)"
    evidence: "60-custom.just uses namespaced names; fedora-cosmic-atomic-dx.just uses bare names. No actual collision. allow-duplicate-recipes claim is wrong."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
  - id: O4
    category: missed-counterexample
    severity: high
    claim: "vscode.repo is validated by validate-repos.sh:55 but not catalogued in the inventory"
    evidence: "The repo is referenced in validation but its origin (base image? dead code from bluefin?) is unknown. Either a missed dependency or dead validation."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
  - id: O5
    category: code-evidence-mismatch
    severity: medium
    claim: "F5 says cosign failure is 'silent' — but missing cosign produces non-zero exit code and red X in GitHub Actions"
    evidence: "build.yml:84-92 has no || true — step failure is observable. The substance (implicit dependency) is correct; the 'silent' characterization is wrong."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
  - id: O6
    category: impression-without-citation
    severity: medium
    claim: "F4 attributes brew-setup's || true to FCA base gotcha — but the gotcha is about systemctl enable, not curl|bash pipes"
    evidence: "AGENTS.md gotcha says 'Guard systemctl enable with || true.' brew-setup is a curl|bash pipe. Attribution is unverifiable speculation."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
  - id: O7
    category: code-evidence-mismatch
    severity: medium
    claim: "F4 cites 'curl | bash' but the actual code wraps it in /bin/bash -c \"\$(...)\""
    evidence: "brew-setup:5 uses /bin/bash -c \"\$(curl ...)\" — same security property, different code citation."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
  - id: O8
    category: pattern-overfitting
    severity: low
    claim: "Pattern #4 groups brew-setup's curl|bash with clean-stage.sh's systemctl guards — but clean-stage.sh uses systemctl (legitimate gotcha), brew-setup uses curl|bash (supply-chain concern)"
    evidence: "clean-stage.sh:12-13 are systemctl operations; brew-setup:5 is a fetched script execution. Different failure modes, different mitigation needs."
    disposition: accepted
    disposition_rationale: "Corrected in the 2026-08-02 revision of the research note."
---

# Adversarial Review: Upstream Dependency Catalog

## Mode: codebase (reviewing codebase-analyst note)

## Reviewer: Explore subagent (independent context — dispatched fresh)

## Total objections: 8 (1 critical, 3 high, 3 medium, 1 low)

## Verdict: FINDINGS — note needs correction before recommendations are actionable

### Critical

**O1 — ublue submodule already has the akmods digest-pinning pattern.** The analyst recommended building digest-pinning for akmods images (R1) without checking whether the upstream reference implementation already solved this. `ublue/Containerfile:8-19` has `AKMODS_DIGEST`/`AKMODS_NVIDIA_DIGEST` ARGs using the same Null Object pattern the project already uses for base/brew images. `ublue/Justfile:165-166` resolves digests from `image-versions.yaml`. R1 should be "adopt the upstream FROM-based akmods pattern" (which eliminates `skopeo copy` entirely) rather than "bolt digest-pinning onto skopeo copy."

### High (3)

- **O2:** `_copr_ublue-os-akmods.repo` is miscategorised as cosmetic — it's conditionally enabled during the kernel install phase
- **O3:** F7's recipe collision claim is wrong — recipe names are different, no `allow-duplicate-recipes` issue
- **O4:** `vscode.repo` validated in `validate-repos.sh:55` but not in the inventory — either missed dependency or dead code

### Medium (3)

- **O5:** F5 says cosign failure is "silent" — actually a loud CI failure (non-zero exit)
- **O6:** F4 attributes `brew-setup`'s `|| true` to FCA base gotcha — gotcha is about systemctl, not curl|bash
- **O7:** F4 cites `curl | bash` but code uses `/bin/bash -c "$(curl ...)"` — same property, wrong citation

### Low (1)

- **O8:** Pattern #4 overfits — groups systemctl guards (legitimate) with curl|bash (supply-chain concern)

## Explicitly not objecting to

1. F2 (COSMIC COPR bus factor): verified — `05-cosmic-upgrade.sh:13`, single-maintainer, hardcoded fedora-44 URL
2. F3 (copr_install_isolated no retry): verified — `copr-helpers.sh:1-22`, zero retry, contrast with Tailscale loop
3. F8 (Flathub URL inconsistency): verified across all three files
4. OCI image inventory (deps #1-4): all four references correctly catalogued
