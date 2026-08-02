---
spec: docs/superpowers/specs/2026-08-02-research-review-gate.md
date: 2026-08-02
mode: code
diaboli_model: DeepSeek V4 Pro
objections:
  - id: O1
    category: implementation
    severity: medium
    claim: "Rule text packs three concerns into one paragraph — gate rule, citation convention, and mode verification."
    evidence: "HARNESS.md lines 72-78. Single paragraph covering gate definition, review record path, disposition clause, citation convention, example path, review record format, and mode verification."
    disposition: deferred
    disposition_rationale: "Density is acceptable for now. Split into separate fields when the constraint gets its first harness-enforcer implementation."
  - id: O2
    category: implementation
    severity: high
    claim: "No mechanism for enforcer to determine which agent produced a research note."
    evidence: "The only existing note has no origin field. Neither path convention nor registry encodes originating agent."
    disposition: accepted
    disposition_rationale: "Add origin: technical-researcher|codebase-analyst to research note YAML frontmatter. Update both agent charters and both skill output formats."
  - id: O3
    category: risk
    severity: medium
    claim: "Example path and objections directory don't exist."
    evidence: "docs/research/2026-08-02-cosmic-keyring.md and docs/research/objections/ do not exist."
    disposition: deferred
    disposition_rationale: "Paths will exist when first research note is created through the pipeline. Example note in rule text is aspirational."
  - id: O4
    category: risk
    severity: low
    claim: "Existing research note has no YAML frontmatter."
    evidence: "docs/research/vscode-install-strategy.md has no YAML frontmatter."
    disposition: accepted
    disposition_rationale: "Add YAML frontmatter with date, question, and origin fields to the existing note."
---

# Code-Mode Review: Research-Reviewer Gate Implementation

## O1 — implementation — medium

### Claim
Rule text packs three separable concerns into one paragraph.

### Evidence
HARNESS.md rule is a single paragraph covering gate definition, review record path, disposition clause, citation convention, example path, review record format, and mode verification. The diaboli constraint is two crisp sentences.

### What's at stake
A harness-enforcer implementer may miss a requirement embedded in the dense prose.

---

## O2 — implementation — high

### Claim
The constraint requires the enforcer to match review mode to note origin, but no mechanism exists for the enforcer to determine which agent produced a given note.

### Evidence
The only existing research note (`docs/research/vscode-install-strategy.md`) has no YAML frontmatter, no origin field, no agent attribution. The constraint says "the harness-enforcer verifies that the review mode matches the note's origin (technical-researcher notes require external mode, codebase-analyst notes require codebase mode)" — but neither the note path convention nor any registry encodes the originating agent.

### What's at stake
Agent enforcement is impossible without origin detection. The constraint would be operationally unverified.

---

## O3 — risk — medium

### Claim
Example path and objections directory don't exist — undefined behaviour for enforcer on first invocation.

### Evidence
Example path `docs/research/2026-08-02-cosmic-keyring.md` doesn't exist. `docs/research/objections/` directory doesn't exist.

### What's at stake
Enforcer may error on missing paths. Low severity because paths will be created by pipeline usage.

---

## O4 — risk — low

### Claim
Existing research note has no YAML frontmatter — enforcer can't parse metadata.

### Evidence
`docs/research/vscode-install-strategy.md` has no YAML frontmatter block. Note predates the constraint.

### What's at stake
If a spec cites this note, the enforcer can't read its origin field. Low severity — one note, fixable.

---

## Explicitly Not Challenged

- The constraint placement after "PRs have adjudicated objections" — correct and matches spec
- The enforcement type (agent), tool (harness-enforcer), and scope (pr) — all match spec
- The rule text content — all FRs are covered despite the density concern
- The citation convention choice (frontmatter field) — reasonable and documented
- The mode-matching requirement — correct logic, just needs origin detection mechanism
