---
task: Phase 3 — CI Pipeline — auto-build and push to ghcr.io
task_slug: phase3-ci-pipeline
date: 2026-06-20
carpaccio_model: deepseek-v4-pro
inseparable: true
progressed_slice: S1
slices:
  - id: S1
    title: GitHub Actions build pipeline
    scope: A single GitHub Actions workflow that watches FCA tags, builds the Containerfile, runs bats tests (structural + build validation), pushes to ghcr.io/jrgrant/atomic-cosmic with versioned tags, and signs with cosign.
    decision_focus: Push strategy (tag naming), cosign key management, build caching
    lens_used: inseparability
    disposition: accepted
    disposition_rationale: Single workflow file — inseparable by nature.
    file_as_issue: false
    issue_url: https://github.com/jrgrant/Atomic/issues/6
    merged_into: null
---

## S1 — CI Pipeline — inseparability

### Context

Phase 3 of the FCA Developer Experience roadmap. Phase 2 delivered the Containerfile and build scripts. This phase automates building and publishing the image. A single `.github/workflows/build.yml` file that triggers on FCA tag changes and PRs.

### Decision content

1. One workflow file: `.github/workflows/build.yml`
2. Triggers: schedule (daily), workflow_dispatch (manual), push to main, PR
3. Steps: checkout → pull base → podman build → bats tests → podman push → cosign sign
4. Tags: `latest`, `44-YYYYMMDD`, `44`
5. Cosign: key stored as GitHub Actions secret `COSIGN_PRIVATE_KEY`, public key in repo

### Dependencies

- Containerfile + build_files/ + system_files/ (Phase 2)
- tests/bats/ (structural + build-validation)
- COSIGN_PRIVATE_KEY secret (user adds to repo settings)
- GHCR write access (automatic for repo owner)

### Rationale

Single file, single concern. The workflow is the deliverable.

---

## Sequencing recommendation

Any order — single slice, inseparable.
