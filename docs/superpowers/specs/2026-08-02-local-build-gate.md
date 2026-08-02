---
date: 2026-08-02
status: accepted
slice: S1 — encode-reflection-constraints
---

# Local Build Gate Constraint

## User Story 1 — Build gate documented

As a contributor, I want the expectation that Containerfile builds pass locally
before CI to be documented in HARNESS.md, so that the convention is explicit
and visible in the project's constraint registry.

### Acceptance Scenarios

1. HARNESS.md contains a "Local build gate" constraint entry
2. The entry uses `unverified` enforcement — no automated check yet
3. The entry is placed in the Constraints section alongside other constraints

## Functional Requirements

- FR1: Add constraint titled "Local build gate"
- FR2: Rule: "Containerfile build must pass locally before CI is re-enabled"
- FR3: Enforcement: unverified, Tool: none yet, Scope: pr
- FR4: Placed after "Research notes require adversarial review" in Constraints

## Implementation Plan

One file: `.claude/HARNESS.md` — add one constraint entry.
