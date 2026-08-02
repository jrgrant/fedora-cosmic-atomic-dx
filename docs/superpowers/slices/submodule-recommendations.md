---
task: "Implement all recommendations from the submodule strategy analysis at docs/research/2026-08-02-submodule-strategy-analysis.md"
task_slug: "submodule-recommendations"
date: "2026-08-02"
carpaccio_model: "DeepSeek V4 Pro"
inseparable: false
progressed_slice: S1
slices:
  - id: "S1"
    title: "Remove m2os submodule"
    scope: "Deinit and remove the m2os git submodule; update HARNESS.md reference table to remove the m2os row; verify no build scripts or configs reference m2os"
    decision_focus: "Whether to remove the m2os submodule now that all migration diffs have been extracted into docs/research/"
    lens_used: "decision-boundary"
    sequencing_note: "Independent of all other slices. If kept, HARNESS.md lifecycle column (S4) would list m2os as deprecated rather than removed."
    disposition: "accepted"
    disposition_rationale: "Zero build dependency confirmed by grep; all migration knowledge extracted to docs/research/; submodule is dead weight adding checkout time and cognitive load."
    file_as_issue: false
    issue_url: null
    merged_into: null
  - id: "S2"
    title: "Add adaptations.yaml bill of materials"
    scope: "Create adaptations.yaml at repo root tracking every build file adapted from bluefin upstream; populate with the five known adaptations (03-install-kernel-akmods.sh, 04-packages.sh, 19-initramfs.sh, 00-dx.sh, build.sh) plus any others found during implementation; each entry records the upstream source path, fork date, upstream commit, and divergence notes"
    decision_focus: "Whether to adopt a structured BOM manifest for provenance tracking, and what schema fields each adaptation entry requires"
    lens_used: "decision-boundary"
    sequencing_note: "Independent of all other slices. Benefits from S4's lifecycle classification (knowing bluefin is active) but does not require it."
    disposition: "accepted"
    disposition_rationale: "Highest-severity finding (F3: high). Provenance tracking is currently implicit comments. BOM enables future CI automation of upstream-diff checking. Schema fields (file, upstream, forked_at, upstream_commit, notes) match the analysis proposal."
    file_as_issue: true
    issue_url: "https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/47"
    merged_into: null
  - id: "S3"
    title: "Pin OCI base images by digest in CI workflow"
    scope: "Add a CI workflow step that resolves the cosmic-atomic:44 and brew:latest image tags to content digests using skopeo inspect, injects the digests into GITHUB_ENV, and passes them as build-args to the Containerfile; the Containerfile already has a BREW_IMAGE_SHA ARG ready for injection; the mutable tags remain in the Containerfile for local development convenience"
    decision_focus: "Whether to pin OCI base images by digest in CI while preserving mutable tags for local dev, and whether skopeo inspect is the right resolution tool"
    lens_used: "decision-boundary"
    sequencing_note: "Independent of all other slices. The Containerfile's existing BREW_IMAGE_SHA ARG means no Containerfile changes are needed."
    disposition: "accepted"
    disposition_rationale: "F4 severity medium. BREW_IMAGE_SHA ARG already exists in Containerfile — digest injection was anticipated but not implemented. skopeo inspect is standard tooling. Mutable tags for local dev + digests for CI is the correct split."
    file_as_issue: true
    issue_url: "https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/48"
    merged_into: null
  - id: "S4"
    title: "Add lifecycle column to HARNESS.md submodule reference table"
    scope: "Add a Lifecycle column to the HARNESS.md Reference Repos table with values stable (fca), active (ublue, bluefin), and deprecated (m2os, or removed if S1 lands first); the column communicates submodule role expectations to contributors"
    decision_focus: "Whether to adopt a lifecycle taxonomy for submodules, and whether the proposed three-tier classification (stable/active/deprecated) is the right set of categories"
    lens_used: "decision-boundary"
    sequencing_note: "Logically independent of S1 — can list m2os as deprecated whether or not it has been physically removed yet. If S1 lands first, the m2os row is simply absent from the table."
    disposition: "accepted"
    disposition_rationale: "Lowest-severity finding (F5: low), cheapest to implement. Three-tier taxonomy (stable/active/deprecated) is sufficient — no need for more granular categories given 3-4 submodules."
    file_as_issue: true
    issue_url: "https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/49"
    merged_into: null
  - id: "S5"
    title: "Document decision to keep flat submodule structure"
    scope: "Write an architecture decision record affirming the flat submodule structure; the analysis concluded that grouping by directory would break path references and add complexity without benefit for a project of this size (~1.3MB across 4 submodules); no code changes — the output is the decision document itself"
    decision_focus: "Whether to accept the analysis's conclusion that the flat structure is adequate and document it, or to pursue directory-grouped restructuring despite the cost"
    lens_used: "decision-boundary"
    sequencing_note: "Independent of all other slices. Can be documented at any point."
    disposition: "accepted"
    disposition_rationale: "Analysis conclusion is sound: directory grouping would break path references across the project with no material benefit for 3-4 submodules totaling ~1.3MB. HARNESS.md documentation (strengthened by S4 lifecycle column) is sufficient."
    file_as_issue: true
    issue_url: "https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/50"
    merged_into: null
---

## S1 — Remove m2os submodule — decision-boundary

### Context

The m2os submodule (368K) was the original OS this project migrated away from.
All build-time and runtime dependencies on m2os have been removed. The analysis
confirmed zero references in `build_files/`, `system_files/`, or `scripts/` —
only documentation references remain. All migration diffs have been extracted
into `docs/research/`. The submodule adds checkout time, CI clone overhead, and
cognitive load (new contributors see "m2os" and wonder if it's still relevant).

### Decision content

Remove the m2os submodule entirely, or keep it as inert documentation.

If removed: `git submodule deinit m2os && git rm m2os`, then update the
HARNESS.md Reference Repos table (remove the m2os row). The extracted
knowledge in `docs/research/` remains accessible.

If kept: it stays as a read-only reference, consuming checkout time with no
build dependency. HARNESS.md should at minimum mark it as deprecated/legacy
(see S4).

### Dependencies

None. No other slice depends on m2os being present or absent.

### Rationale

This is the highest-certainty recommendation in the analysis (F1 severity:
medium, zero build dependency, all knowledge extracted). The decision is
whether the team considers the extracted docs sufficient or wants to retain
the live submodule for future diff reference against the upstream.

### Implementation Plan

**Files modified:**

| File | Action |
|------|--------|
| `.gitmodules` | Remove `[submodule "m2os"]` section |
| `.git/modules/m2os/` | Removed by `git submodule deinit` |
| `m2os/` (working tree) | Removed by `git rm` |
| `.claude/HARNESS.md` | Remove m2os row from Reference Repos table |

**Algorithm notes:**

- The removal is a standard git submodule removal: `git submodule deinit m2os && git rm m2os`. No `--force` needed — the submodule has no local modifications.
- The HARNESS.md table edit removes one row. Column alignment must be preserved for the remaining three rows.
- The analysis already confirmed zero build references: `grep -rl m2os build_files/ system_files/ scripts/ Containerfile` returns nothing. No further verification of build scripts is needed — the grep is the verification.
- `.gitignore` contains no m2os-specific patterns that would need cleanup.

**FR mapping:**

| FR | Description |
|----|-------------|
| FR1 | `.gitmodules` must not contain m2os entry |
| FR2 | `git submodule status` must not list m2os |
| FR3 | HARNESS.md Reference Repos table must not contain m2os row |

**Test cases:**

| ID | Test |
|----|------|
| T1 | `grep -c '\[submodule "m2os"\]' .gitmodules` returns 0 |
| T2 | `test -d m2os` returns false |
| T3 | `grep -c 'm2os' .claude/HARNESS.md` returns 0 in table context |

---

## S2 — Add adaptations.yaml bill of materials — decision-boundary

### Context

The project adapts build scripts from bluefin upstream. Some files carry
provenance comments (`03-install-kernel-akmods.sh`), but most adapted files
have no attribution at all (`04-packages.sh`, `19-initramfs.sh`, `00-dx.sh`,
`build.sh`). There is no structured manifest tracking which files are adapted,
from where, or at what upstream commit they were forked. When bluefin upstream
changes, there is no automated way to determine which of our files need review
— the monthly GC rule requires manual judgment for every file.

### Decision content

Adopt a structured BOM as `adaptations.yaml` at the repo root. The analysis
proposes a schema with fields: `file`, `upstream`, `forked_at`,
`upstream_commit`, and `notes`. The implementation would populate entries for
all five known adaptations plus any others discovered during authoring.

The human decision is twofold: (a) adopt the BOM pattern at all, and (b)
confirm or revise the proposed schema fields. The schema design determines
what future automation (CI diff-against-upstream) can leverage.

### Dependencies

None. The BOM can be authored independently of all other slices. It benefits
from knowing bluefin's lifecycle classification (S4) but does not require it.

### Rationale

This is the highest-severity finding in the analysis (F3: high). Provenance
tracking is currently implicit — a handful of comments — and there is no
structured way to answer "did bluefin change something we adapted?" The BOM
is a prerequisite for any future automation of that question.

### Implementation Plan

**Files modified:**

| File | Action |
|------|--------|
| `adaptations.yaml` | Create — new file at repo root |

**Algorithm notes:**

- Schema: top-level `adaptations` key containing a list of mappings. Each mapping has `file`, `upstream`, `forked_at`, `notes` (required) and `upstream_commit` (optional — populated where the bluefin submodule's git history identifies the fork point).
- The five known adaptations are documented in the spec. Any additional adapted files discovered during implementation (e.g., if `grep -rl "Adapted from bluefin" build_files/` returns more than five results) are added to the list.
- The `forked_at` date for each file can be determined from the Phase 2 implementation date (2026-06-20) — that is when the build scripts were initially ported. This is documented in `docs/superpowers/specs/2026-06-20-phase2-containerfile-mvp-design.md` and confirmed by git history of the build_files/ directory.
- The `upstream_commit` field should be populated by checking the bluefin submodule's commit at the time of forking: `git -C bluefin log --oneline --until="2026-06-20" -- build_files/base/03-install-kernel-akmods.sh | head -1`. If the submodule's history doesn't go back that far (possible after submodule updates), omit the field.
- YAML structure follows the analysis proposal. No anchors or aliases needed — each entry is self-contained.

**FR mapping:**

| FR | Description |
|----|-------------|
| FR4 | `adaptations.yaml` must exist at repo root and parse as valid YAML |
| FR5 | Must contain entries for all five known bluefin adaptations |
| FR6 | Each entry must include `file`, `upstream`, `forked_at`, `notes` |
| FR7 | Every file listed must exist on disk |

**Test cases:**

| ID | Test |
|----|------|
| T4 | `python3 -c "import yaml; yaml.safe_load(open('adaptations.yaml'))"` succeeds |
| T5 | Entry count >= 5 |
| T6 | Every entry has non-empty required fields |
| T7 | Every `file` path exists on disk |
| T8 | `yamllint adaptations.yaml` passes |

---

## S3 — Pin OCI base images by digest in CI workflow — decision-boundary

### Context

The Containerfile uses mutable tags: `quay.io/fedora-ostree-desktops/cosmic-atomic:44`
and `ghcr.io/ublue-os/brew:latest`. Submodules are pinned by commit hash (git
default), but OCI image dependencies float. A rebuild with the same commit can
produce a different image if the base or brew layer changed between builds.
The Containerfile already has a `BREW_IMAGE_SHA` ARG (currently empty for
local builds), providing a ready injection point.

### Decision content

Add a CI workflow step that resolves the mutable tags to content digests at
build time using `skopeo inspect`, injects the digests via `GITHUB_ENV`, and
passes them as `--build-arg` to the Containerfile. The mutable tags remain in
the Containerfile for local development — only CI pins by digest.

The human decision is whether digest pinning in CI is worth the operational
cost of the `skopeo inspect` step, and whether the mutable-tags-for-local +
digests-for-CI split is the right strategy.

### Dependencies

None. The Containerfile's existing `BREW_IMAGE_SHA` ARG means no
Containerfile changes are needed — this is purely a CI workflow change.

### Rationale

This addresses F4 (severity: medium). The existing `BREW_IMAGE_SHA` ARG
suggests digest injection was already anticipated but not implemented. The
analysis makes the inconsistency between submodule pinning (by commit) and
image pinning (by mutable tag) explicit.

### Implementation Plan

**Files modified:**

| File | Action |
|------|--------|
| `.github/workflows/build.yml` | Add two `skopeo inspect` steps before the build step; inject digests via `GITHUB_ENV`; pass as `--build-arg` to `podman build` |

**Algorithm notes:**

- `skopeo inspect` is part of the `containers-common` or `skopeo` package. On Ubuntu runners, it may need explicit install: `sudo apt-get install -y skopeo`.
- Two resolution steps, one for each image:
  1. `skopeo inspect docker://quay.io/fedora-ostree-desktops/cosmic-atomic:44 --format '{{.Digest}}'` → `BASE_IMAGE_DIGEST` env var
  2. `skopeo inspect docker://ghcr.io/ublue-os/brew:latest --format '{{.Digest}}'` → `BREW_IMAGE_SHA` env var (reuses existing ARG name)
- The digests are written to `$GITHUB_ENV` so subsequent steps can reference them.
- The `podman build` command receives `--build-arg BASE_IMAGE_DIGEST=$BASE_IMAGE_DIGEST --build-arg BREW_IMAGE_SHA=$BREW_IMAGE_SHA`.
- The Containerfile must consume these ARGs in its FROM lines. Currently the Containerfile has `ARG BREW_IMAGE_SHA=""` (defined but not consumed in FROM) and no `BASE_IMAGE_DIGEST` ARG. These are likely needed: `FROM ${BREW_IMAGE}@${BREW_IMAGE_SHA} AS brew` and `FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}@${BASE_IMAGE_DIGEST}`. The user context states no Containerfile changes are needed — if the ARG consumption turns out to be missing, it is a trivial one-line addition per FROM.
- The existing "Pull base image (cached)" step in the workflow uses the mutable tag for layer caching. This step should remain as-is (it caches layers for faster builds) — the digest pinning applies to the actual Containerfile build, not the cache pull.
- `set -euo pipefail` or `|| exit 1` on each skopeo call ensures CI fails if resolution fails.

**FR mapping:**

| FR | Description |
|----|-------------|
| FR8 | CI resolves cosmic-atomic:44 to digest |
| FR9 | CI resolves brew:latest to digest |
| FR10 | Digests injected via `--build-arg` |
| FR11 | Containerfile mutable tags unchanged for local dev |
| FR12 | CI fails if skopeo cannot resolve either image |

**Test cases:**

| ID | Test |
|----|------|
| T9 | CI workflow YAML parses cleanly |
| T10 | `grep -c 'skopeo inspect' .github/workflows/build.yml` returns >= 2 |
| T11 | `grep -c 'BREW_IMAGE_SHA\|BASE_IMAGE_DIGEST' .github/workflows/build.yml` returns >= 1 |

---

## S4 — Add lifecycle column to HARNESS.md submodule reference table — decision-boundary

### Context

The HARNESS.md Reference Repos table currently has three columns: Submodule,
Upstream, Purpose. It treats all four submodules as equal peers, but they have
fundamentally different roles: fca is a stable base, bluefin is the active
adaptation source, ublue provides infrastructure, and m2os is legacy/dead
weight. The analysis (F5) found that the flat presentation doesn't communicate
these role differences to contributors.

### Decision content

Add a Lifecycle column to the HARNESS.md table with a three-tier taxonomy:
`stable` (fca — tracks fedora-atomic-desktops, low churn), `active` (ublue,
bluefin — primary adaptation and infrastructure sources), `deprecated` (m2os
— pending removal per R1). If S1 lands first, the m2os row is simply absent.

The human decision is which taxonomy to use. The analysis proposes
stable/active/deprecated. Alternatives could include a different tier set or
more granular categories.

### Dependencies

Logically independent of S1. The lifecycle column can list m2os as
`deprecated` whether or not the submodule has been physically removed. If S1
lands first, the m2os row is absent from the table and the lifecycle column
applies to the remaining three submodules.

### Rationale

This is the lowest-severity finding (F5: low) and the cheapest recommendation
to implement — a single table column in an existing document. The value is
primarily onboarding: new contributors see at a glance which submodules are
active dependencies and which are not.

### Implementation Plan

**Files modified:**

| File | Action |
|------|--------|
| `.claude/HARNESS.md` | Add `Lifecycle` column to Reference Repos table |

**Algorithm notes:**

- Add `Lifecycle` as the fourth column in the Reference Repos table header: `| Submodule | Upstream | Purpose | Lifecycle |`.
- Add a separator row with four columns: `| --------- | -------- | ------- | --------- |`.
- Populate the Lifecycle column for each remaining submodule:
  - `fca/` → `stable`
  - `ublue/` → `active`
  - `bluefin/` → `active`
- If S1 (m2os removal) has already landed, the m2os row is absent — only three rows. If S1 has not yet landed, add a `deprecated` lifecycle value for the m2os row.
- The three-tier taxonomy (stable/active/deprecated) matches the analysis proposal. No new taxonomy values are introduced.

**FR mapping:**

| FR | Description |
|----|-------------|
| FR13 | Table must include Lifecycle column |
| FR14 | fca row shows `stable` |
| FR15 | ublue row shows `active` |
| FR16 | bluefin row shows `active` |

**Test cases:**

| ID | Test |
|----|------|
| T12 | `grep -c 'Lifecycle' .claude/HARNESS.md` returns >= 1 in table context |
| T13 | fca table row contains `stable` |
| T14 | ublue table row contains `active` |
| T15 | bluefin table row contains `active` |

---

## S5 — Document decision to keep flat submodule structure — decision-boundary

### Context

The analysis (F5) considered whether grouping submodules by directory (e.g.,
`upstream/bluefin`, `upstream/ublue`) would improve clarity. It concluded that
directory grouping would break existing path references throughout the project
and add complexity without material benefit for a project of this size (~1.3MB
across 4 submodules). The recommendation (R5) is to keep the flat structure
and rely on HARNESS.md documentation (strengthened by S4's lifecycle column)
to communicate roles.

### Decision content

Explicitly affirm the flat submodule structure by documenting it as an
architecture decision. The output is a decision record — either a new ADR in
`docs/superpowers/adr/` or an entry in `AGENTS.md` under `ARCH_DECISIONS`.

The human decision is whether to accept the analysis's conclusion, or to
pursue directory-grouped restructuring despite the path-breaking cost.

### Dependencies

None. This is a documentation-only slice with no code changes.

### Rationale

This is the only recommendation with zero code change. It exists because the
analysis raised the question (F5) and answered it — the human needs to either
affirm that answer or override it. Without explicit documentation, the
question will recur for future contributors who notice the flat structure and
wonder whether it was intentional or accidental.

### Implementation Plan

**Files modified:**

| File | Action |
|------|--------|
| `docs/superpowers/adr/2026-08-02-flat-submodule-structure.md` | Create — new ADR, OR |
| `AGENTS.md` | Add entry under `ARCH_DECISIONS` |

**Algorithm notes:**

- Preferred output: a standalone ADR at `docs/superpowers/adr/2026-08-02-flat-submodule-structure.md`, following the pattern established by `docs/superpowers/adr/2026-08-02-split-research-architecture.md`.
- ADR structure: YAML frontmatter (`date`, `status: accepted`), then standard sections: Context, Decision, Alternatives Considered, Consequences.
- The decision is: keep flat submodule structure. No directory grouping (e.g., `upstream/`) is introduced.
- Rationale to include: project scale (~1.3MB across 3-4 submodules), path references would break if submodules moved, HARNESS.md lifecycle column (S4) provides sufficient role communication.
- Alternative to document: grouping by directory (e.g., `upstream/bluefin`, `upstream/ublue`). Rejected because path breakage cost exceeds clarity benefit at this scale.
- If recorded in AGENTS.md instead: a concise entry under `ARCH_DECISIONS` following the existing pattern (Decision, Reason, Alternatives considered).

**FR mapping:**

| FR | Description |
|----|-------------|
| FR17 | ADR exists at expected path or in AGENTS.md |
| FR18 | ADR records decision, rationale, and alternative considered |
| FR19 | ADR has `date: 2026-08-02` and `status: accepted` in frontmatter |

**Test cases:**

| ID | Test |
|----|------|
| T16 | ADR file exists or AGENTS.md ARCH_DECISIONS entry exists |
| T17 | YAML frontmatter contains `status: accepted` |
| T18 | Text references project scale (~1.3MB, 3–4 submodules) |
| T19 | Text mentions directory-grouping alternative was considered and rejected |

---

## Sequencing recommendation

All five slices are independent — no slice blocks any other. They can be
implemented in any order.

A natural sequence if proceeding together:

1. **S1** (remove m2os) — remove dead weight first, simplifying the table
   that S4 updates
2. **S4** (lifecycle column) — document roles for the remaining submodules
3. **S2** (adaptations.yaml) — create the BOM, now that the active adaptation
   source (bluefin) is clearly identified
4. **S3** (digest pinning) — orthogonal CI change, can slot in anywhere
5. **S5** (flat-structure ADR) — document the decision, closes the loop on F5

---

## Explicitly not slicing on

- **Per-file adaptation entries within R2.** The BOM is a single manifest
  artifact. Individual entries (which files, what metadata) are content, not
  separate decisions — they are populated during implementation of the one
  slice.

- **CI automation of BOM-based upstream-diff checking.** The analysis mentions
  that "CI can diff upstream changes against this manifest and flag files
  needing review" as a forward-looking benefit of R2. That automation is not
  part of the five recommendations and is not sliced here. It would be a
  separate task once the BOM exists.

- **Automated GC rule updates for submodule staleness.** The existing GC rules
  (`## Submodule staleness` in HARNESS.md) already check for drift. S4's
  lifecycle column is informational only — it does not change the GC check
  logic. A future task could make the GC rule lifecycle-aware (e.g., skip
  deprecated submodules), but that is not in the current recommendations.

- **Containerfile changes for digest pinning.** The Containerfile already has
  a `BREW_IMAGE_SHA` ARG and the `BASE_IMAGE`/`FEDORA_MAJOR_VERSION` split
  pattern. S3 is purely a CI workflow change — no Containerfile modification
  is needed.

- **Validation infrastructure for adaptations.yaml.** The recommendations do
  not include a CI validation rule (e.g., YAML schema check for the BOM). The
  existing `scripts/ai-literacy-check.sh` could be extended to validate the
  BOM, but that is not part of R2's scope as written.
