# Research Adversarial Review Gate — Constraint Spec

**Date**: 2026-08-02
**Status**: draft
**Issue**: N/A (trivial — single HARNESS.md entry, derived from REFLECTION_LOG.md)
**Slice**: S3 of `docs/superpowers/slices/encode-reflection-constraints.md`

## 1. Problem

The research pipeline was split into three context-isolated agents in PR #39
(codebase-analyst, technical-researcher, research-reviewer — see
`docs/superpowers/adr/2026-08-02-split-research-architecture.md`). The pipeline
requires that no research note is acted upon without a research-reviewer pass,
but HARNESS.md has no constraint encoding this gate.

The same reasoning that produced the "PRs have adjudicated objections" constraint
(advocatus-diaboli adversarial review before spec approval) applies to research
findings: unexamined research notes that propagate into specs, design decisions,
or implementation choices carry the same risks as unadjudicated spec objections
— confirmation bias, source misreading, and unstated assumptions entering the
SDLC artefact chain undetected.

## 2. Scope

One new constraint entry in `.claude/HARNESS.md`, inserted after the existing
"PRs have adjudicated objections" constraint. No other files change.

## 3. Design

### 3.1 Constraint entry

```
### Research notes require adversarial review

- **Rule**: No research note may be acted upon without a research-reviewer pass
  (objection record exists at `docs/research/objections/<date>-<slug>-review.md`
  with all dispositions resolved). "Acted upon" means used as the basis for a
  spec change, design decision, or implementation choice in any PR.
- **Enforcement**: agent
- **Tool**: harness-enforcer
- **Scope**: pr
```

A "research-reviewer pass" is defined as: a review record exists at
`docs/research/objections/<date>-<slug>-review.md` with all dispositions
resolved. This mirrors the existing diaboli constraint exactly: both gates
require an objection record whose dispositions are all resolved before the
artefact may proceed.

The research-reviewer produces a structured objection record at
`docs/research/objections/<date>-<slug>-review.md` with YAML frontmatter
including `mode: external|codebase`. The harness-enforcer reads this
frontmatter to verify the review mode matches the note's origin
(codebase-analyst notes require codebase-mode review; technical-researcher
notes require external-mode review).

### 3.2 Placement

Inserted immediately after "PRs have adjudicated objections." The two constraints
form a pair: spec-level adversarial review (advocatus-diaboli) and research-level
adversarial review (research-reviewer). Grouping them makes the symmetry visible.

### 3.3 Citation convention

For the harness-enforcer to mechanically identify which research notes a PR acts
upon, spec files must declare referenced research notes in their frontmatter.
The convention is a `Research:` field listing note paths:

```
**Research**: [docs/research/2026-08-02-cosmic-keyring.md]
```

- The field is optional — absent when the spec cites no research notes
- Multiple notes are listed comma-separated: `[path1.md, path2.md]`
- Paths are relative to the repository root
- The harness-enforcer reads spec files to find this field, then verifies that
  each listed path has a corresponding review record with all dispositions
  resolved

## 4. User stories

### US1 — Research gate enforced at PR time

**As** a project maintainer
**I want** harness-enforcer to verify that any research note cited in a PR has a
research-reviewer pass
**So that** unexamined research findings cannot propagate into specs or
implementation without adversarial scrutiny.

Acceptance scenarios:

1. **PR cites a research note with reviewer pass** — harness-enforcer passes the
   constraint check
2. **PR cites a research note without reviewer pass** — harness-enforcer blocks
   the constraint check, reports the uncertified note
3. **PR cites no research notes** — harness-enforcer passes (no research to
   review, constraint is vacuously satisfied)
4. **PR cites a research note reviewed in external mode** — harness-enforcer
   reads the review record's YAML frontmatter at
   `docs/research/objections/<date>-<slug>-review.md`, confirms `mode: external`
   matches the note's origin (technical-researcher), and passes
5. **PR cites a research note reviewed in codebase mode** — harness-enforcer
   reads the review record's YAML frontmatter, confirms `mode: codebase`
   matches the note's origin (codebase-analyst), and passes

## 5. Files to modify

| File | Action |
|---|---|
| `.claude/HARNESS.md` | Add one constraint entry after "PRs have adjudicated objections" |

## 6. Functional requirements

| ID | Requirement | Source |
|----|-------------|--------|
| FR1 | HARNESS.md must contain a constraint titled "Research notes require adversarial review" | US1 |
| FR2 | The constraint rule must state: "No research note may be acted upon without a research-reviewer pass (objection record exists at `docs/research/objections/<date>-<slug>-review.md` with all dispositions resolved)" | US1 |
| FR3 | The constraint must use `agent` enforcement, `harness-enforcer` tool, `pr` scope — matching "PRs have adjudicated objections" | US1 |
| FR4 | The constraint must be placed immediately after "PRs have adjudicated objections" | US1 |
| FR5 | Spec files must support a `Research:` frontmatter field listing referenced research note paths, relative to repo root | US1 |
| FR6 | The harness-enforcer must read spec files for the `Research:` field and verify each listed note has a corresponding review record at `docs/research/objections/<date>-<slug>-review.md` with all dispositions resolved | US1 |
| FR7 | The harness-enforcer must read the review record's YAML frontmatter `mode:` field and verify it matches the note's origin (external for technical-researcher notes, codebase for codebase-analyst notes) | US1 |

## 7. Exclusions

- No implementation of the harness-enforcer check itself — the agent already
  exists; this spec only adds the constraint declaration and citation convention
- No changes to CI or scripts
- The `Research:` field is optional in spec frontmatter; specs without it are
  not required to add it retroactively

## 8. Test cases

| ID | Test | Covers |
|----|------|--------|
| T1 | Verify HARNESS.md parses successfully (YAML frontmatter, markdown structure) | FR1—FR4 |
| T2 | Verify the new constraint entry exists with title "Research notes require adversarial review" | FR1 |
| T3 | Verify the rule text includes "with all dispositions resolved" and the review record path | FR2 |
| T4 | Verify enforcement field is "agent" | FR3 |
| T5 | Verify tool field is "harness-enforcer" | FR3 |
| T6 | Verify scope field is "pr" | FR3 |
| T7 | Verify the constraint appears after "PRs have adjudicated objections" in the file | FR4 |
| T8 | Verify HARNESS.md documents the `Research:` frontmatter field convention and review record format | FR5, FR6 |
| T9 | Verify the spec itself (this file) uses the `Research:` field if it references research notes | FR5 |
