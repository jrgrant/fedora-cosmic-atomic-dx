---
spec: docs/superpowers/specs/2026-08-02-research-review-gate.md
date: 2026-08-02
mode: spec
diaboli_model: DeepSeek V4 Pro
objections:
  - id: O1
    category: specification quality
    severity: high
    claim: "The spec never defines what constitutes a 'research-reviewer pass' in terms the harness-enforcer can mechanically verify."
    evidence: "Section 3.1: 'No research note may be acted upon without a research-reviewer pass.' The existing constraint this mirrors says 'with all dispositions resolved' — the proposed text drops the disposition clause without explanation."
    disposition: accepted
    disposition_rationale: "Define 'research-reviewer pass' as 'review record exists with all dispositions resolved' — exact mirror of diaboli. Update spec rule text."
  - id: O2
    category: implementation
    severity: high
    claim: "The harness-enforcer has no defined mechanism for discovering which research notes a PR acts upon."
    evidence: "Section 3.1 defines 'acted upon' as 'used as the basis for a spec change, design decision, or implementation choice in any PR.' The spec provides no citation convention, metadata field, or structured reference format that would let the enforcer mechanically identify which PRs trigger this check."
    disposition: accepted
    disposition_rationale: "Spec must define citation convention. Simplest: Research: footer in spec frontmatter listing note paths. Enforcer reads spec files for this field."
  - id: O3
    category: specification quality
    severity: medium
    claim: "Acceptance scenarios 4 and 5 require the enforcer to distinguish external from codebase review modes, but the spec never references how the review mode is recorded."
    evidence: "AS4 and AS5 require mode verification. The research-reviewer agent records mode in its output YAML frontmatter, but the spec does not reference this artefact."
    disposition: accepted
    disposition_rationale: "Spec should reference research-reviewer output format at docs/research/objections/<date>-<slug>-review.md with mode: in YAML frontmatter."
  - id: O4
    category: specification quality
    severity: medium
    claim: "The spec drops the 'all dispositions resolved' clause from the constraint it claims to mirror, without acknowledging or justifying the omission."
    evidence: "The existing constraint reads 'with all dispositions resolved.' The proposed text reads 'without a research-reviewer pass.' These are materially different gates: a review file could exist while still having pending dispositions."
    disposition: accepted
    disposition_rationale: "Include 'with all dispositions resolved' in rule text. No justification needed — should have been in the original."
  - id: O5
    category: alternatives
    severity: low
    claim: "The constraint could start as unverified enforcement, promoting to agent-enforced once the detection mechanism is proven."
    evidence: "Three existing constraints already use unverified enforcement with documented intent to promote later. Research notes are optional and citation conventions don't yet exist."
    disposition: rejected
    disposition_rationale: "We want agent enforcement. O1/O2 fix the spec gap — the constraint is enforceable once the spec defines 'pass' and the citation convention. Unverified is a fallback, not a preference."
---

# Adversarial Review: Research Review Gate Constraint

## O1 — specification quality — high

### Claim

The spec never defines what constitutes a "research-reviewer pass" in terms the
harness-enforcer can mechanically verify.

### Evidence

Section 3.1 proposes the constraint rule:

> No research note may be acted upon without a research-reviewer pass.

Compare the existing constraint this mirrors (from HARNESS.md):

> Every feature or behaviour-change PR must have a spec-mode objection record
> with all dispositions resolved

The existing constraint explicitly names the checkable condition: "all
dispositions resolved." The proposed constraint replaces this with "a
research-reviewer pass" — a term the spec never defines.

A "pass" could mean any of:
- A review file exists at `docs/research/objections/*-review.md`
- The review file has zero objections
- All dispositions in the review file are resolved (matching the diaboli precedent)
- The review found no critical or high objections

Each definition would produce different enforcer behaviour. The spec must
choose one.

### Why this matters

Without a definition of "pass," two implementers will build different checks.
The constraint would be declared as agent-enforced but operationally unverified.

---

## O2 — implementation — high

### Claim

The harness-enforcer has no defined mechanism for discovering which research
notes a PR acts upon.

### Evidence

Section 3.1 defines the trigger condition: "'Acted upon' means used as the
basis for a spec change, design decision, or implementation choice in any PR."

The spec provides no citation convention, metadata field, or structured
reference format. The "PRs have adjudicated objections" constraint works because
every feature PR has a corresponding spec with a predictable path convention.
Research notes are optional — only some PRs cite them. Without a citation
convention, the enforcer cannot determine which notes to check.

### Why this matters

The constraint will either never fire (vacuous) or fire on every PR
(indiscriminate). The spec must define the citation convention before the
constraint can be agent-enforced.

---

## O3 — specification quality — medium

### Claim

Acceptance scenarios 4 and 5 require the enforcer to distinguish external from
codebase review modes, but the spec never references how the review mode is
recorded.

### Evidence

AS4: "PR cites a research note reviewed in external mode — harness-enforcer
passes (reviewer mode matches note origin)." AS5: same for codebase mode.

The research-reviewer agent records `mode: external|codebase` in its output YAML
frontmatter, but the spec does not reference this artefact, its format, or its
location.

### Why this matters

Scenarios 4 and 5 are untestable as written. The spec should note that the
research-reviewer produces a structured objection record at a predictable path.

---

## O4 — specification quality — medium

### Claim

The spec drops the "all dispositions resolved" clause from the constraint it
claims to mirror, without acknowledging or justifying the omission.

### Evidence

The existing constraint: "with all dispositions resolved." The proposed: "without
a research-reviewer pass." A review file can exist while still carrying pending
dispositions. These are materially different gates.

### Why this matters

If the intent is to match the diaboli precedent exactly, the rule text should
say "with all dispositions resolved." If the intent is different, the spec
should explain why.

---

## O5 — alternatives — low

### Claim

The constraint could start as unverified enforcement, promoting to agent-enforced
once the detection mechanism is proven.

### Evidence

Three existing constraints use unverified enforcement with documented intent to
promote later. Research notes are optional and citation conventions don't yet
exist. Starting unverified avoids building an enforcer check against an undefined
trigger.

### Why this matters

If O1 and O2 are accepted (the spec doesn't define "pass" or the citation
convention), then agent enforcement is premature. Unverified enforcement
acknowledges this honestly.

---

## Explicitly Not Objecting To

- **The gate's necessity**: the research pipeline should have adversarial
  review. The objection is to the spec's underspecification, not the concept
- **The enforcement type choice**: agent enforcement matching the diaboli
  precedent is the right tier once the spec is complete
- **The scope choice**: pr scope is correct — research notes are a PR-level
  concern, not a commit-level one
- **The HARNESS.md format**: the constraint entry format (Rule, Enforcement,
  Tool, Scope) is consistent with existing constraints
- **The ADR alignment**: the constraint is consistent with the architecture
  documented in `docs/superpowers/adr/2026-08-02-split-research-architecture.md`
