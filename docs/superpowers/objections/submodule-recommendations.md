---
spec: docs/superpowers/specs/2026-08-02-submodule-recommendations.md
date: 2026-08-02
mode: spec
diaboli_model: DeepSeek V4 Pro
objections:
  - id: O1
    category: scope
    severity: high
    claim: "The spec asserts no Containerfile changes are needed, but US3 requires a BASE_IMAGE_DIGEST ARG that does not exist in the current Containerfile."
    evidence: "Exclusions section: 'No Containerfile changes.' US3 acceptance scenario 3: 'A corresponding BASE_IMAGE_DIGEST ARG handles the FCA base image.' Containerfile (actual): no BASE_IMAGE_DIGEST ARG exists — the FROM line is `FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}` with no digest-injection mechanism for the base image."
    disposition: accepted
    disposition_rationale: "Valid — the spec contradicts itself. Resolution: remove 'No Containerfile changes' from exclusions, add `ARG BASE_IMAGE_DIGEST=\"\"` to Containerfile (one line, mirrors existing BREW_IMAGE_SHA pattern). The FROM line becomes `FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}@${BASE_IMAGE_DIGEST:-}` which is a no-op when the ARG is empty (local dev)."
  - id: O2
    category: specification quality
    severity: high
    claim: "US3 is internally contradictory: it requires a Containerfile mechanism (BASE_IMAGE_DIGEST ARG) that the spec's own exclusions forbid creating."
    evidence: "US3 scenario 3: 'A corresponding BASE_IMAGE_DIGEST ARG handles the FCA base image.' Exclusions: 'No Containerfile changes.' These two statements cannot both be true."
    disposition: accepted
    disposition_rationale: "Same root cause as O1. Resolution: drop the 'No Containerfile changes' exclusion and document the minimal Containerfile change (one ARG line). The exclusion was overly conservative — the research analysis correctly noted no Containerfile changes were NEEDED for BREW_IMAGE_SHA, but base-image pinning requires a symmetric ARG."
  - id: O3
    category: premise
    severity: medium
    claim: "The spec omits F2 (ublue-bluefin parent-child redundancy) without justification for why 268K of documentation-only submodule is acceptable when 368K (m2os) is dead weight."
    evidence: "F2: '17 of 18 ublue references are in docs/specs.' F1: 'zero results outside docs/.' The spec never explains why the asymmetry in recommendations."
    disposition: accepted
    disposition_rationale: "Valid observation. The ublue submodule has one active build dependency (brew image reference in Containerfile) vs. m2os's zero. F2 severity was low vs. F1's medium. But the spec should explicitly note this. Resolution: add a line to the Scope section: 'F2 (ublue-bluefin overlap) is documented as low severity with a legitimate one-dependency justification — no action at this time.'"
  - id: O4
    category: risk
    severity: medium
    claim: "The CI workflow's existing podman pull step creates a digest-resolution race: skopeo inspect resolves tag→digest A, then podman pull re-resolves the same mutable tag (now possibly digest B)."
    evidence: "CI workflow already runs `podman pull quay.io/fedora-ostree-desktops/cosmic-atomic:${{ env.FEDORA_VERSION }}` before build. skopeo inspect would be a separate tag resolution."
    disposition: accepted
    disposition_rationale: "Moot if O5 is accepted (use podman image inspect instead of skopeo). If skopeo is retained, the existing podman pull step should use the resolved digest. Resolution: adopt O5's alternative — extract digest from the already-pulled image via podman image inspect, eliminating both the race and the extra tool dependency."
  - id: O5
    category: alternatives
    severity: medium
    claim: "The spec adds skopeo as a new tool dependency when podman image inspect on the already-pulled image provides the same digest without additional tooling or network calls."
    evidence: "CI workflow already runs podman pull. `podman image inspect --format '{{.Digest}}'` extracts the digest from the pulled image."
    disposition: accepted
    disposition_rationale: "Correct — podman image inspect is simpler, eliminates the race (O4), removes the skopeo install question (O9), and uses tooling already in the workflow. Resolution: replace skopeo inspect with podman image inspect post-pull. The pull step serves double duty: cache population + digest extraction."
  - id: O6
    category: risk
    severity: medium
    claim: "The adaptations.yaml BOM has no enforcement mechanism — YAML validation and upstream-diff CI are deferred, leaving the BOM vulnerable to silent staleness."
    evidence: "Exclusions: 'No new CI validation steps beyond digest resolution.' US2 scenario 4 requires BOM accuracy but has no ongoing enforcement."
    disposition: accepted
    disposition_rationale: "Acknowledged gap. Resolution: add a GC rule to HARNESS.md: 'BOM integrity: monthly check that every adaptations.yaml file entry exists on disk and every Adapted from bluefin/ comment in build_files/ has a BOM entry.' This is a zero-new-tool enforcement using existing grep + yaml validation. The GC agent can run it alongside the existing submodule staleness check."
  - id: O7
    category: risk
    severity: medium
    claim: "Removing the m2os submodule may break documentation references — the analysis confirms m2os references exist in docs/, but the spec only addresses HARNESS.md."
    evidence: "F1: 'grep -rl m2os build_files/ system_files/ scripts/ returns zero results outside docs/.' FR1-FR3 cover .gitmodules, git status, and HARNESS.md only."
    disposition: accepted
    disposition_rationale: "Valid gap. Resolution: add US1 acceptance scenario: 'Documentation references are updated — grep -rl m2os docs/ returns zero matches or only references in research notes that describe the historical m2os migration (which are intentionally preserved).' The implementer runs the grep and updates any docs that would have dead links."
  - id: O8
    category: specification quality
    severity: medium
    claim: "US5 permits two fundamentally different destinations for the ADR — standalone file or AGENTS.md entry — with different durability characteristics."
    evidence: "US5 scenario 1: 'A file at docs/superpowers/adr/... exists, or the decision is recorded in AGENTS.md.' AGENTS.md is 'often generated or updated by LLM agents.'"
    disposition: accepted
    disposition_rationale: "Correct — these are not equivalent. Resolution: mandate the standalone ADR path (docs/superpowers/adr/2026-08-02-flat-submodule-structure.md), following the existing ADR pattern (2026-08-02-split-research-architecture.md). This is the durable, immutable format. AGENTS.md is too volatile for architectural decisions."
  - id: O9
    category: risk
    severity: medium
    claim: "The spec hedges on skopeo availability ('may need explicit install') but US3 scenario 5 only covers resolution errors, not tool absence."
    evidence: "Slice notes: 'skopeo is a related package that may need explicit install.' US3 scenario 5 covers network/registry errors only."
    disposition: accepted
    disposition_rationale: "Moot if O5 is accepted (switch to podman image inspect). podman is already a CI dependency (the workflow uses `podman pull` and `podman build`). No new tool, no install question."
  - id: O10
    category: specification quality
    severity: low
    claim: "US4's test cases cover only the three retained submodules but not the m2os-deprecated scenario (S4 landing before S1)."
    evidence: "T13-T15 cover fca/stable, ublue/active, bluefin/active. No test for m2os/deprecated."
    disposition: accepted
    disposition_rationale: "Valid gap but low impact — S1 (m2os removal) is progressed and will land first in this pipeline run. If S4 ever lands independently, the acceptance scenario text is clear. Resolution: add T16: 'If m2os row exists in HARNESS.md, it must contain deprecated.'"
  - id: O11
    category: implementation
    severity: low
    claim: "The adaptations.yaml forked_at field uses a single project-milestone date (2026-06-20) for all five files, reducing provenance fidelity."
    evidence: "S2 implementation plan: 'The forked_at date for each file can be determined from the Phase 2 implementation date (2026-06-20).' Files may have diverged on different commits."
    disposition: accepted
    disposition_rationale: "Acknowledged but low impact. The upstream_commit field (when populated) provides commit-level precision. forked_at as a uniform date is acceptable given all five files were ported in the same Phase 2 window. Resolution: populate upstream_commit where recoverable from git history; use 2026-06-20 as forked_at for all entries with a note that this is the Phase 2 milestone date."
  - id: O12
    category: scope
    severity: low
    claim: "FR7 (every file listed must exist on disk) is tested at authoring time (T7) but has no ongoing enforcement."
    evidence: "FR7 + T7 test at authoring time. Exclusions defer CI validation."
    disposition: accepted
    disposition_rationale: "Covered by the O6 resolution (GC rule for BOM integrity). The monthly GC check includes file-existence validation, addressing the ongoing enforcement gap."
---

## O1 — scope — high

### Claim
The spec asserts no Containerfile changes are needed, but US3 requires a `BASE_IMAGE_DIGEST` ARG that does not exist in the current Containerfile.

### Resolution
Remove "No Containerfile changes" from exclusions. Add `ARG BASE_IMAGE_DIGEST=""` to Containerfile (mirrors existing `BREW_IMAGE_SHA` pattern). The FROM becomes `FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}@${BASE_IMAGE_DIGEST:-}` — no-op when ARG is empty (local dev).

---

## O2 — specification quality — high

### Claim
US3 requires a Containerfile mechanism that the spec's exclusions forbid.

### Resolution
Same root cause as O1. Drop the "No Containerfile changes" exclusion. The Containerfile change is minimal: one ARG line, one FROM tweak.

---

## O5 — alternatives — medium (key design pivot)

### Claim
Use `podman image inspect` instead of `skopeo inspect` — eliminates the race condition (O4), removes the tool-install question (O9), and reuses an existing CI step.

### Resolution
**Accepted.** This is the key design change from the diaboli review. The CI workflow already runs `podman pull` before build. Extracting the digest from the pulled image is simpler and eliminates the race:
```bash
podman pull quay.io/fedora-ostree-desktops/cosmic-atomic:44
BASE_DIGEST=$(podman image inspect quay.io/fedora-ostree-desktops/cosmic-atomic:44 --format '{{.Digest}}')
echo "BASE_IMAGE_DIGEST=${BASE_DIGEST}" >> $GITHUB_ENV
```

---

## Explicitly not objecting to

- Three-tier lifecycle taxonomy (stable/active/deprecated) — sufficient for 3-4 submodules
- YAML format for adaptations.yaml — consistent with project conventions
- Deferring automated upstream-diff CI — BOM is the prerequisite, format needs real-world use first
- The flat submodule structure decision — analysis conclusion is well-reasoned
- Slice independence — correctly identified; edge cases documented
- grep for build-reference verification — reasonable structural check
- Omission of ublue-only recommendation — low severity, one legitimate dependency
