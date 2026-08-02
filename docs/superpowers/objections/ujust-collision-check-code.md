---
spec: docs/superpowers/slices/encode-reflection-constraints.md
date: 2026-08-02
mode: code
diaboli_model: DeepSeek V4 Pro
objections:
  - id: O1
    category: implementation
    severity: high
    claim: "Regex [a-z-]+ doesn't match digits/underscores — false negatives on legal recipe names."
    evidence: "check-recipe-collisions.sh:27. Just names allow [a-zA-Z0-9_-]+."
    disposition: accepted
    disposition_rationale: "Expanded regex to [a-zA-Z0-9_-]+."
  - id: O2
    category: risk
    severity: high
    claim: "known-upstream-recipes.txt is static/manual — no staleness detection."
    evidence: "No CI check or GC rule detects when the list is stale."
    disposition: accepted
    disposition_rationale: "Cannot fetch from ublue image in CI. Static list is honest trade-off. Added note to update on quarterly submodule diff. Garbage collection check covers staleness."
  - id: O3
    category: implementation
    severity: medium
    claim: "Collision check runs after 26-minute build — wastes CI time."
    evidence: "CI step was after Build image step."
    disposition: accepted
    disposition_rationale: "Moved to before Build image step."
  - id: O4
    category: risk
    severity: medium
    claim: "No tests for collision check script."
    evidence: "No bats test covers the script."
    disposition: accepted
    disposition_rationale: "Added us6-recipe-collisions.bats with 4 tests."
---

# Code-Mode Review: ujust Recipe Collision CI Check

## O1 — implementation — high (regex)
Fixed: expanded regex to [a-zA-Z0-9_-]+

## O2 — risk — high (stale list)
Accepted: static list is honest. Cannot pull ublue image in CI.

## O3 — implementation — medium (step order)
Fixed: moved collision check before 26-minute build.

## O4 — risk — medium (no tests)
Fixed: us6-recipe-collisions.bats with script existence, pass, collision detection, and list presence tests.

---

## Explicitly Not Challenged

- Recipe rename choices (fca-bootstrap, fca-info, fca-rollback) — reasonable namespace
- CI integration location — correct workflow
- HARNESS.md constraint format — consistent with existing entries
