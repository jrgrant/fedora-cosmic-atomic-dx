---
spec: docs/superpowers/specs/2026-08-02-research-review-gate.md
date: 2026-08-02
mode: spec
cartographer_model: DeepSeek V4 Pro
stories:
  - id: 1
    lens: [patterns]
    title: "Layered adversarial gates — diaboli and reviewer as a pair"
    disposition: pending
    disposition_rationale: null
  - id: 2
    lens: [forces]
    title: "Symmetry over domain-specific gate design"
    disposition: pending
    disposition_rationale: null
  - id: 3
    lens: [alternatives]
    title: "HARNESS.md constraint over CI, hook, or charter encoding"
    disposition: pending
    disposition_rationale: null
  - id: 4
    lens: [defaults]
    title: "Agent enforcement inherited from diaboli precedent"
    disposition: pending
    disposition_rationale: null
  - id: 5
    lens: [consequences]
    title: "Optional Research field — gate vacuously satisfied by omission"
    disposition: pending
    disposition_rationale: null
  - id: 6
    lens: [alternatives]
    title: "Frontmatter citation over separate registry or inline annotations"
    disposition: pending
    disposition_rationale: null
---

## Story #1 — Layered adversarial gates — diaboli and reviewer as a pair

**Source:** `docs/superpowers/specs/2026-08-02-research-review-gate.md` §3.1, §3.2
**Lens:** patterns
**Refs:** O1, O4

**Context.** The spec adds a research-reviewer gate constraint to HARNESS.md and
deliberately places it immediately after the existing "PRs have adjudicated
objections" constraint. The two constraints share the same enforcement type
(agent), tool (harness-enforcer), scope (pr), and disposition clause ("all
dispositions resolved"). The spec calls them "a pair" (§3.2) and notes the
symmetry is intentional.

**Forces.** The spec could have designed a research-specific gate with its own
format, enforcement tier, and scope — research notes are a different artefact
type than specs, and the failure modes differ. The force toward symmetry was
operational simplicity: one enforcement mechanism, one tool, one cognitive model
for contributors. The force toward domain-specific design was fit-for-purpose:
a research note is not a spec, and the review cadence and scope might differ.

**Options not taken.**

- **Domain-specific enforcement tier.** The constraint could have used
  `unverified` enforcement initially (as O5 proposed) and promoted later, or
  `deterministic` enforcement via a CI script that checks for review record
  existence. The spec chose agent enforcement to match the diaboli precedent.
- **Different scope.** Research review could have been scoped to `commit` (check
  on every push) or made a manual gate (review before dispatch) rather than a PR
  gate. The spec chose `pr` to match the diaboli precedent.
- **Standalone constraint with no grouping.** The constraint could have been
  placed alphabetically or in a research-specific section rather than explicitly
  paired with the diaboli constraint.

**Choice as written.** The spec chose exact structural mirroring — same
enforcement (agent), same tool (harness-enforcer), same scope (pr), same
disposition clause — and explicit adjacent placement to make the pairing
visible.

**Consequences.** Future adversarial gates (e.g., for implementation review,
test-quality review) will face pressure to conform to this same structure. The
pair establishes a template — any deviation will need justification. This is
both a benefit (consistency) and a constraint (less flexibility for
domain-specific gate design).

**Pattern.** This is an instance of the **Layers** pattern (Buschmann et al.,
*Pattern-Oriented Software Architecture* Vol. 1, 1996) applied to quality gates:
each SDLC layer (research, specification) has its own adversarial check with the
same interface shape but different domain content. The ADR at
`docs/superpowers/adr/2026-08-02-split-research-architecture.md` explicitly
states the research pipeline "mirrors the main pipeline's
spec-writer→advocatus-diaboli pattern."

---

## Story #2 — Symmetry over domain-specific gate design

**Source:** `docs/superpowers/specs/2026-08-02-research-review-gate.md` §3.1
**Lens:** forces
**Refs:** O4

**Context.** The constraint rule text reads: "No research note may be acted upon
without a research-reviewer pass (objection record exists at
`docs/research/objections/<date>-<slug>-review.md` with all dispositions
resolved)." This is a near-verbatim structural mirror of the diaboli constraint:
"Every feature or behaviour-change PR must have a spec-mode objection record
with all dispositions resolved."

**Forces.** The spec resolved an unspoken tension between two competing
principles. **Symmetry:** one mental model for all adversarial gates — if you
know how the diaboli gate works, you know how the research-reviewer gate works.
Contributors learn one pattern. **Domain fit:** research notes are structurally
different from specs. They are narrower, more granular, and more numerous. A
research-specific gate could, for example, support partial review (review only
the sections of a note that a spec actually cites) or different disposition
semantics (a research note might not need the full accepted/deferred/rejected
triad). The spec resolved entirely toward symmetry without naming the tension.

**Options not taken.**

- **Partial review scope.** The gate could check that the *cited portions* of a
  research note are reviewed, not the entire note. This would reduce review
  latency for long notes where only one finding is cited.
- **Simplified disposition model for research.** Research objections might only
  need `accepted` and `rejected` — no `deferred` — since research notes are
  point-in-time findings, not living documents like specs.
- **Different pass criteria.** A research-reviewer pass could require zero
  objections of `high` severity only, rather than all dispositions resolved.

**Choice as written.** The spec chose to replicate the diaboli constraint
structure exactly: same pass definition ("all dispositions resolved"), same
artefact path pattern (`objections/<date>-<slug>-review.md`), same enforcement
metadata.

**Consequences.** Any future refinement to the research-reviewer gate (e.g.,
partial review, severity-based pass criteria) will either break the symmetry or
require the diaboli gate to adopt the same refinement. The constraints are
coupled by design.

**Pattern.** —

---

## Story #3 — HARNESS.md constraint over CI, hook, or charter encoding

**Source:** `docs/superpowers/specs/2026-08-02-research-review-gate.md` §3.1, §5
**Lens:** alternatives
**Refs:** O5

**Context.** The spec encodes the research-reviewer gate as a HARNESS.md
constraint entry with `Enforcement: agent`, `Tool: harness-enforcer`, and
`Scope: pr`. This is the same encoding as the diaboli constraint — but it was
not the only place the gate could have lived.

**Forces.** HARNESS.md constraints are the project's established mechanism for
declaring enforced rules. The force toward encoding there was consistency with
the existing constraint set and support from the harness-enforcer
infrastructure. The force toward other locations was domain proximity: a CI
check is closer to the build pipeline, a git hook catches violations earlier, an
orchestrator charter rule lives with the agent that dispatches research.

**Options not taken.**

- **CI check (deterministic enforcement).** A `scripts/check-research-review.sh`
  that scans spec frontmatter for `Research:` fields and verifies each cited
  note has a review record. This would have been a direct CI check rather than
  an agent-mediated one. Rejected implicitly — the spec chose agent enforcement,
  which routes through harness-enforcer.
- **Orchestrator charter rule.** The orchestrator agent's charter could require
  research-reviewer passes before dispatching implementation from a spec that
  cites research. This would catch violations earlier (at dispatch time, not PR
  time). The spec chose PR-time enforcement instead.
- **Git hook.** A pre-push or commit-msg hook that warns or blocks when a spec
  file's diff adds a `Research:` field without a corresponding review record.
  Rejected implicitly — no hook infrastructure exists in the project.

**Choice as written.** The spec chose HARNESS.md constraint encoding with agent
enforcement via harness-enforcer at PR scope. The §5 table lists only
`.claude/HARNESS.md` as modified — no CI files, no hook scripts, no charter
updates.

**Consequences.** The gate fires at PR time, not earlier. A contributor can
write a spec citing unreviewed research, push the branch, open a PR, and only
then discover the violation. Earlier detection (at commit or dispatch time)
would reduce the fix loop but require infrastructure the project doesn't yet
have.

**Pattern.** —

---

## Story #4 — Agent enforcement inherited from diaboli precedent

**Source:** `docs/superpowers/specs/2026-08-02-research-review-gate.md` §3.1
**Lens:** defaults
**Refs:** O5

**Context.** The spec sets `Enforcement: agent` — matching the diaboli
constraint. Objection O5 proposed `Enforcement: unverified` as a lower-risk
starting point, citing three existing unverified constraints with documented
intent to promote later. The disposition rejected O5: "We want agent
enforcement. O1/O2 fix the spec gap — the constraint is enforceable once the
spec defines 'pass' and the citation convention."

**Forces.** Agent enforcement provides an active gate: the harness-enforcer
reads spec frontmatter and review records and blocks the PR if the gate isn't
satisfied. Unverified enforcement is a documented expectation with no mechanical
check — it relies on human discipline. The force toward agent enforcement was
consistency with the diaboli precedent and a belief that the constraint is
operationally complete after O1–O4 were accepted. The force toward unverified
was risk reduction: if the citation convention or pass definition proved
incomplete in practice, an unverified constraint would be a documentation gap
rather than a false-positive gate blocking legitimate PRs.

**Options not taken.**

- **Unverified initially, promote later.** Start with `Enforcement: unverified`
  and a comment noting intent to promote after the citation convention and
  enforcer check have been exercised on real PRs. This was O5's proposal.
- **Deterministic enforcement via CI script.** A standalone script rather than
  agent-mediated enforcement, matching the project's deterministic constraints
  (shellcheck, gitleaks).
- **Advisory agent enforcement.** A softer variant where the harness-enforcer
  warns but doesn't block — not currently supported by the harness-enforcer
  model, but a design option.

**Choice as written.** The spec chose `Enforcement: agent` — the same tier as
the diaboli constraint — and the slicing record at
`docs/superpowers/slices/encode-reflection-constraints.md` confirms "Agent
enforcement via harness-enforcer, pr scope."

**Consequences.** If the citation convention proves insufficient in practice
(e.g., a spec cites a research note indirectly through an ADR rather than
directly in its `Research:` field), the gate will either miss violations or
require spec authors to adopt a citation discipline they didn't anticipate. The
diaboli constraint has a structural advantage the research gate lacks: every
feature PR has a spec with a predictable path, so the diaboli gate fires
deterministically. The research gate fires only when the `Research:` field is
present — the mechanical trigger is opt-in.

**Pattern.** —

---

## Story #5 — Optional Research field — gate vacuously satisfied by omission

**Source:** `docs/superpowers/specs/2026-08-02-research-review-gate.md` §3.3, §7
**Lens:** consequences
**Refs:** #2, #4

**Context.** The spec declares the `Research:` frontmatter field optional
("absent when the spec cites no research notes," §3.3) and explicitly excludes
retroactive addition ("specs without it are not required to add it
retroactively," §7). A spec that cites no research notes passes the constraint
vacuously — the harness-enforcer has nothing to check.

**Forces.** The spec resolved an adoption-friction vs. completeness tension
toward low friction. Making the field mandatory would require every existing
spec to be audited for research-note dependencies and retrofitted with
`Research:` citations. Making it optional means the gate is silent for any spec
whose author omits the field — whether intentionally (no research was used) or
not (research was used but not cited).

**Options not taken.**

- **Mandatory field, empty by default.** Every spec file must include
  `Research: []` — the harness-enforcer verifies the field exists but passes
  when empty. This would make citation discipline visible and auditable without
  requiring retroactive content review.
- **Diaboli-checked citations.** The advocatus-diaboli objection categories
  could include a "missing research citation" check — the diaboli asks "did this
  spec use research that isn't cited?" during spec review. This would catch
  omissions through the existing adversarial review pipeline rather than the
  harness-enforcer.
- **Research-note-side registration.** Research notes could declare their own
  dependents rather than specs declaring their dependencies. A "Cited by:" field
  in the research note's frontmatter, updated by the spec author at citation
  time. Rejected implicitly — the spec chose spec-side declaration.

**Choice as written.** The spec chose an optional `Research:` field with no
mechanical check for uncited research usage. Detection of missing citations
relies on the human reviewer (diaboli or research-reviewer) noticing the gap.

**Consequences.** The gate is not hermetic. A spec author who omits the
`Research:` field — whether by oversight or choice — produces no enforcer
violation. The constraint catches only *declared* research dependencies, not
*actual* ones. This is a deliberate tradeoff, not a bug: the spec acknowledges
it in §7. The project accepts that citation completeness is a human discipline,
not a mechanical one.

**Pattern.** —

---

## Story #6 — Frontmatter citation over separate registry or inline annotations

**Source:** `docs/superpowers/specs/2026-08-02-research-review-gate.md` §3.3
**Lens:** alternatives
**Refs:** O2

**Context.** Objection O2 identified that the original spec had no mechanism for
the harness-enforcer to discover which research notes a PR acts upon. The
accepted disposition specified: "Simplest: `Research:` footer in spec
frontmatter listing note paths." The revised spec adopted this — a
comma-separated list of repo-relative paths in YAML frontmatter.

**Forces.** The spec needed a machine-readable citation format that the
harness-enforcer could parse without opening every file in the repo. Frontmatter
is already parsed by the enforcer for other fields — adding `Research:` is a
low-cost extension. The force toward a separate registry was discoverability: a
single CITATIONS.md or research-index.json would make all research→spec
relationships visible in one place. The force toward inline annotations was
precision: a citation in prose near the claim it supports is more informative
than a path in metadata.

**Options not taken.**

- **Separate registry file.** A `docs/research/CITATIONS.md` mapping research
  note paths to the specs that cite them. This would make the full citation
  graph visible in one read without scanning every spec file. The harness
  complexity is higher — the enforcer would need to verify bidirectional
  consistency (spec says it cites X, registry says X is cited by spec).
- **Inline annotations in prose.** Markdown link syntax in the spec body, e.g.,
  `[research note](docs/research/2026-08-02-cosmic-keyring.md)` with a review
  status convention. This would place the citation near the claim it supports
  but would require the enforcer to parse prose Markdown rather than structured
  frontmatter.
- **Git trailer convention.** `Research-note:` trailers in commit messages. This
  would tie citations to commits rather than specs and would require the
  enforcer to scan git history.

**Choice as written.** The spec chose YAML frontmatter with a `Research:` field
containing a comma-separated list of repo-relative markdown paths in brackets.
The format is `[path1.md, path2.md]` — a simple list serialisation rather than
structured YAML.

**Consequences.** Citations are scoped to the spec file, not to individual
claims within the spec. A spec that cites three research notes doesn't indicate
which note supports which functional requirement. This is sufficient for the
gate's purpose (verify review exists) but insufficient for finer-grained
traceability (verify the right review addresses the right claim).

**Pattern.** This is a **microformat** convention — a lightweight structured
field embedded in an existing document format rather than a separate registry or
a full citation ontology. The format inherits from the project's existing YAML
frontmatter convention used by specs, objections, and ADRs.
