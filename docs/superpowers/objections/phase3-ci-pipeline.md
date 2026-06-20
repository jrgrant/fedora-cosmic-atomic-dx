---
spec: docs/superpowers/specs/2026-06-20-phase3-ci-pipeline-design.md
date: 2026-06-20
mode: spec
diaboli_model: deepseek-v4-pro
objections:
  - id: O1
    category: risk
    severity: medium
    claim: Daily schedule trigger will rebuild every day even if FCA hasn't changed — wastes CI minutes and pushes identical images
    evidence: "§2.1: schedule: daily. No diff-before-build gate. The workflow will pull the base image, build, test, and push every 24 hours regardless of whether the FCA base changed. This is wasteful on a free-tier GitHub Actions quota."
    disposition: accepted
    disposition_rationale: Add a diff gate — compare FCA digest with last build before proceeding.
  - id: O2
    category: implementation
    severity: low
    claim: cosign.pub committed but cosign.key must be manually added as a secret — the spec doesn't document the key generation step for the user
    evidence: "§2.4 mentions COSIGN_PRIVATE_KEY but doesn't document 'cosign generate-key-pair' or where to add the secret in GitHub. A README or setup section is missing."
    disposition: accepted
    disposition_rationale: Add setup instructions in the spec and a note in the workflow comments.
  - id: O3
    category: scope
    severity: low
    claim: No caching strategy — every build pulls the full base image from quay.io
    evidence: "§2.2 step 3: 'Pull base — cosmic-atomic:44 (cached)'. The 'cached' annotation is aspirational — GitHub Actions doesn't cache podman layers by default. Without explicit registry caching or layer caching, this will be slow and bandwidth-heavy."
    disposition: deferred
    disposition_rationale: GitHub Actions has 14-day cache retention. Add a digest check to skip builds when nothing changed (O1 fix mitigates this). Layer caching can be added later.
---

## Explicitly not objecting to

1. **Single workflow file** — correct for a simple pipeline
2. **Tagging strategy** — `44`, `44-YYYYMMDD`, `latest` is standard
3. **PR validation without push** — correct security boundary
