---
spec: docs/superpowers/specs/2026-08-02-submodule-recommendations.md
date: 2026-08-02
mode: code
diaboli_model: deepseek-v4-pro
objections:
  - id: O1
    category: implementation
    severity: high
    claim: "adaptations.yaml is missing three files whose headers declare they were adapted from bluefin."
    evidence: "grep 'Adapted from bluefin' build_files/ returns 8 files; adaptations.yaml tracked only 5. Missing: build_files/shared/build-dx.sh, build_files/base/17-cleanup.sh, build_files/base/00-image-info.sh."
    disposition: accepted
    disposition_rationale: "Fixed — all 8 adapted files now tracked in adaptations.yaml. The research analysis only identified 5; the grep-based discovery during implementation revealed the other 3."
  - id: O2
    category: implementation
    severity: high
    claim: "CI uses podman image inspect for digest resolution; spec FR8/FR9 said skopeo inspect."
    evidence: "Spec FR8/FR9 referenced skopeo inspect. Implementation uses podman image inspect per code-reviewer's diaboli review decision."
    disposition: accepted
    disposition_rationale: "Fixed — spec FR8, FR9, FR12, T10, Scope, and Exclusions updated to reflect podman image inspect. The skopeo→podman pivot was the correct decision (no new tool, no race condition) but the spec wasn't updated to match."
  - id: O3
    category: specification quality
    severity: medium
    claim: "Spec FR5 mandates exactly 5 files but US2 scenario 4 mandates completeness — the spec's own requirement revealed the BOM was incomplete."
    disposition: accepted
    disposition_rationale: "Fixed — FR5 updated to 'every file under build_files/ whose header comment declares adaptation from bluefin (currently 8 files).' The spec now mandates completeness, not a fixed count."
  - id: O4
    category: risk
    severity: medium
    claim: "Base image digest resolution is coupled to the prior pull step — if reordered or removed, inspect breaks."
    disposition: accepted
    disposition_rationale: "Acknowledged. The coupling is intentional and documented in the CI comment: 'Uses podman image inspect (not skopeo) — podman is already pulled as a dependency.' The pull step is the immediate predecessor. If the workflow is restructured, the guard (empty-digest check) will catch the failure."
  - id: O5
    category: implementation
    severity: medium
    claim: "adaptations.yaml has zero upstream_commit values despite the spec requiring population where identifiable."
    disposition: accepted
    disposition_rationale: "Acknowledged but kept as-is. The bluefin submodule was added after the Phase 2 port — the fork point predates the submodule's inclusion. The forked_at date (2026-06-20) is the best available provenance marker. upstream_commit will be populated for future adaptations where the fork point is captured at creation time."
  - id: O6
    category: specification quality
    severity: medium
    claim: "Spec Scope said 'No change modifies the Containerfile' but the implementation requires ARG additions."
    disposition: accepted
    disposition_rationale: "Fixed — spec Scope and Exclusions updated to reflect the minimal Containerfile change (one ARG line + FROM syntax). This was already flagged by spec-mode diaboli (O1/O2) and should have been fixed in the spec earlier."
  - id: O7
    category: risk
    severity: medium
    claim: "No validation that resolved digests are non-empty before passing to build."
    disposition: accepted
    disposition_rationale: "Fixed — added `if [ -z \"$DIGEST\" ]; then echo ERROR; exit 1; fi` guards after each podman image inspect step. CI now fails on empty digest, satisfying FR12."
---

## O1 — implementation — high

### Claim
adaptations.yaml was missing 3 files with "Adapted from bluefin" headers.

### Resolution
Added entries for build-dx.sh, 17-cleanup.sh, and 00-image-info.sh. BOM now tracks all 8 adapted files.

## O2 — implementation — high

### Claim
Spec referenced skopeo inspect; implementation uses podman image inspect.

### Resolution
Updated spec FR8, FR9, FR12, T10, Scope, and Exclusions to reflect the podman-based approach. This was the correct design decision from the spec-mode diaboli review — the spec just wasn't updated.

## O7 — risk — medium

### Claim
No guard against empty digest values.

### Resolution
Added `if [ -z "$DIGEST" ]` guards in both CI resolution steps.

## Explicitly not objecting to

- The ${VAR:+@${VAR}} syntax in Containerfile — correct and verified
- The Lifecycle column taxonomy — stable/active is sufficient for 3 submodules
- The flat-structure ADR — well-reasoned, follows existing ADR pattern
- The adaptations.yaml schema — comprehensive, well-documented
- The naming inconsistency (BREW_IMAGE_SHA vs BASE_IMAGE_DIGEST) — acknowledged in Containerfile preamble, not worth the churn of renaming a pre-existing ARG
- The build step wiring — correctly consumes both digest ARGs
- The yamllint fix — document-start marker + line-length compliance
