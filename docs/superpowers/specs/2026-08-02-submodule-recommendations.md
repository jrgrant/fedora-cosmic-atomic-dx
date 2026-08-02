---
date: 2026-08-02
status: drafted
carpaccio_slug: submodule-recommendations
carpaccio_total_slices: 5
source_analysis: docs/research/2026-08-02-submodule-strategy-analysis.md
---

# Submodule Strategy Recommendations — Spec

## 1. Problem

The submodule strategy analysis (`docs/research/2026-08-02-submodule-strategy-analysis.md`)
identified five actionable recommendations to reduce dead weight, strengthen
provenance tracking, improve build reproducibility, clarify submodule roles,
and document architectural decisions. All five recommendations were accepted
after review. This spec describes the expected behaviour changes from a user's
perspective before implementation begins.

## 2. Scope

Five independent changes across git configuration, project manifests, CI
workflow, HARNESS.md documentation, and architecture decision records.
The Containerfile receives a minimal change (one ARG line, FROM syntax
update) for base-image digest pinning, mirroring the existing brew-image
pattern. Build scripts and system_files are unchanged.

## 3. User Stories

### US1 — Remove m2os submodule (R1)

**As** a contributor cloning the repository
**I want** the m2os submodule to be removed
**So that** checkout time is reduced, CI clones are faster, and I don't wonder
whether a legacy OS (368K of code) is still relevant to the build.

Acceptance scenarios:

1. **Submodule is gone** — `git submodule status` no longer lists m2os.
   `.gitmodules` contains no `[submodule "m2os"]` entry. The `m2os/` directory
   does not exist on disk after `git clone --recurse-submodules`.

2. **HARNESS.md updated** — The Reference Repos table in
   `.claude/HARNESS.md` has no row for m2os. The table lists exactly three
   submodules: `fca/`, `ublue/`, and `bluefin/`.

3. **No build references remain** — `grep -r m2os build_files/ system_files/
   scripts/ Containerfile` returns zero matches. (The analysis confirmed this
   was already true — the scenario verifies no regression.)

### US2 — Add adaptations.yaml bill of materials (R2)

**As** a developer maintaining build scripts adapted from bluefin upstream
**I want** a structured bill of materials (`adaptations.yaml`) at the repo root
**So that** I can identify which files were adapted from upstream, when they
were forked, and what diverged — enabling automated upstream-diff checking in
future CI.

Acceptance scenarios:

1. **BOM file exists and is valid** — `adaptations.yaml` exists at the repo
   root and parses as valid YAML. The top-level key is `adaptations`, containing
   a list of adaptation entries.

2. **Five known adaptations are tracked** — The list contains entries for
   `build_files/base/03-install-kernel-akmods.sh`,
   `build_files/base/04-packages.sh`,
   `build_files/base/19-initramfs.sh`,
   `build_files/dx/00-dx.sh`, and
   `build_files/shared/build.sh`.

3. **Each entry has required fields** — Every adaptation entry includes:
   `file` (path relative to repo root), `upstream` (path within the bluefin
   submodule), `forked_at` (ISO date), and `notes` (free-text describing what
   diverged from upstream). The `upstream_commit` field is populated where the
   fork point is identifiable from git history; omitted otherwise.

4. **No missing adaptations** — Every file under `build_files/` whose header
   comment says "Adapted from bluefin/" appears in `adaptations.yaml`.
   Conversely, every `file` listed in `adaptations.yaml` exists on disk.

5. **ShellCheck passes if the BOM is referenced from a script** — Not
   applicable: `adaptations.yaml` is a data file, not a script.

### US3 — Pin OCI base images by digest in CI (R3)

**As** a release engineer rebuilding an older commit
**I want** CI builds to resolve mutable image tags (`:44`, `:latest`) to
content-addressable digests before building
**So that** rebuilding the same commit produces the same image, regardless of
what upstream has pushed in the meantime.

Acceptance scenarios:

1. **CI resolves cosmic-atomic:44 to a digest** — The build workflow
   (`.github/workflows/build.yml`) runs `skopeo inspect` against
   `quay.io/fedora-ostree-desktops/cosmic-atomic:44` and captures the
   `Digest` field before the Containerfile build step.

2. **CI resolves brew:latest to a digest** — The workflow runs `skopeo
   inspect` against `ghcr.io/ublue-os/brew:latest` and captures the
   `Digest` field before the Containerfile build step.

3. **Digests are passed to the Containerfile** — The resolved digests are
   injected via `GITHUB_ENV` and passed as `--build-arg` values to `podman
   build`. The Containerfile's existing `BREW_IMAGE_SHA` ARG receives the
   brew digest. A corresponding `BASE_IMAGE_DIGEST` ARG handles the FCA
   base image.

4. **Mutable tags still work locally** — The Containerfile's default ARG
   values (mutable tags) are unchanged. Running `podman build .` without
   `--build-arg` uses the mutable tags as before.

5. **skopeo failure fails the build** — If `skopeo inspect` cannot resolve
   an image tag (network error, registry down, tag removed), the CI job
   fails with a clear error message rather than falling back to mutable tags.

6. **COPR chroot resolution is unaffected** — The digest-pinned base image
   still has `ID=fedora` in its `os-release`, so dnf5 COPR chroot resolution
   inside the build continues to work. (This is a gotcha documented in
   AGENTS.md — verified by inspection, not a new behaviour.)

### US4 — Add lifecycle column to HARNESS.md Reference Repos table (R4)

**As** a new contributor reading HARNESS.md
**I want** a Lifecycle column in the Reference Repos table
**So that** I can immediately see which submodules are actively developed
against, which are stable baselines, and which are deprecated — without
reading the full analysis.

Acceptance scenarios:

1. **Table has a Lifecycle column** — The Reference Repos table in
   `.claude/HARNESS.md` includes a `Lifecycle` column between `Purpose`
   and the existing columns.

2. **fca is marked stable** — The fca row shows `stable` in the Lifecycle
   column, reflecting its role as the immutable base image config.

3. **ublue and bluefin are marked active** — Both ublue and bluefin rows
   show `active`, reflecting ongoing adaptation and monitoring.

4. **m2os is absent** — With S1 (R1) executed first, no m2os row exists.
   If S1 is not yet merged, the row shows `deprecated`.

5. **Table remains readable** — The table renders correctly in both
   rendered Markdown and plain-text views. Column alignment is preserved.

### US5 — Document decision to keep flat submodule structure (R5)

**As** a future contributor wondering why submodules are flat at the repo root
rather than grouped under `upstream/`
**I want** a concise architecture decision record explaining the rationale
**So that** I don't re-litigate a question the project has already resolved.

Acceptance scenarios:

1. **ADR exists** — A file at `docs/superpowers/adr/2026-08-02-flat-submodule-structure.md`
   exists, or the decision is recorded in `AGENTS.md` under ARCH_DECISIONS.

2. **ADR states the decision** — The document clearly states: the submodule
   structure remains flat (no directory grouping such as `upstream/`).

3. **ADR states the rationale** — The document explains: directory grouping
   would break path references across the project with no material benefit
   for 3–4 submodules totaling ~1.3MB; HARNESS.md documentation (with lifecycle
   column from R4) is sufficient for communicating submodule roles.

4. **ADR notes the alternative considered** — The document records that
   grouping by directory (e.g. `upstream/bluefin`, `upstream/ublue`) was
   considered and rejected.

5. **ADR has correct frontmatter** — The document includes YAML frontmatter
   with `date: 2026-08-02` and `status: accepted`.

## 4. Functional Requirements

| ID | Requirement | Source |
|----|------------|--------|
| FR1 | `.gitmodules` must not contain a `[submodule "m2os"]` entry | US1 |
| FR2 | `git submodule status` must not list m2os | US1 |
| FR3 | `.claude/HARNESS.md` Reference Repos table must not contain an m2os row | US1 |
| FR4 | `adaptations.yaml` must exist at the repo root and parse as valid YAML | US2 |
| FR5 | `adaptations.yaml` must contain entries for every file under `build_files/` whose header comment declares adaptation from bluefin (currently 8 files) | US2 |
| FR6 | Each adaptation entry must include `file`, `upstream`, `forked_at`, and `notes` fields | US2 |
| FR7 | Every file listed in `adaptations.yaml` must exist on disk | US2 |
| FR8 | `.github/workflows/build.yml` must include a step that resolves `quay.io/fedora-ostree-desktops/cosmic-atomic:44` to a digest via `podman image inspect` after pulling the image | US3 |
| FR9 | `.github/workflows/build.yml` must include a step that resolves `ghcr.io/ublue-os/brew:latest` to a digest via `podman image inspect` after pulling the image | US3 |
| FR10 | Resolved digests must be injected into the Containerfile build via `--build-arg` | US3 |
| FR11 | Containerfile default ARG values (mutable tags) must remain unchanged for local development | US3 |
| FR12 | CI must fail if digest resolution cannot produce a non-empty digest for either image | US3 |
| FR13 | `.claude/HARNESS.md` Reference Repos table must include a `Lifecycle` column | US4 |
| FR14 | The fca row must show `stable` in the Lifecycle column | US4 |
| FR15 | The ublue row must show `active` in the Lifecycle column | US4 |
| FR16 | The bluefin row must show `active` in the Lifecycle column | US4 |
| FR17 | An ADR must exist at `docs/superpowers/adr/2026-08-02-flat-submodule-structure.md` or the decision must be recorded in `AGENTS.md` ARCH_DECISIONS | US5 |
| FR18 | The ADR must record the decision (keep flat), rationale (no benefit for project scale), and alternative considered (directory grouping) | US5 |
| FR19 | The ADR must have YAML frontmatter with `date: 2026-08-02` and `status: accepted` | US5 |

## 5. Exclusions

- Containerfile change is minimal: one ARG line + FROM syntax update for
  base-image digest pinning, mirroring the existing brew-image pattern.
  No other Containerfile modifications.
- No changes to build scripts under `build_files/`
- No changes to system_files
- No changes to `.gitignore` (m2os removal leaves no orphaned ignore patterns)
- No new CI validation steps beyond digest resolution (YAML parsing validation
  for `adaptations.yaml` is deferred to a future CI enhancement)
- The adaptations.yaml BOM does not yet include an automated upstream-diff
  CI check — it establishes the data format that makes such checks possible

## 6. Test Cases

| ID | Test | Covers |
|----|------|--------|
| T1 | `grep -c '\[submodule "m2os"\]' .gitmodules` returns 0 | FR1 |
| T2 | `test -d m2os` returns false (directory absent) | FR2 |
| T3 | `grep -c 'm2os' .claude/HARNESS.md` returns 0 in Reference Repos table context | FR3 |
| T4 | `python3 -c "import yaml; yaml.safe_load(open('adaptations.yaml'))"` succeeds | FR4 |
| T5 | `python3 -c "import yaml; d=yaml.safe_load(open('adaptations.yaml')); assert len(d['adaptations']) >= 5"` | FR5 |
| T6 | Every entry in adaptations.yaml has non-empty `file`, `upstream`, `forked_at`, `notes` | FR6 |
| T7 | Every `file` path in adaptations.yaml exists on disk (`test -f`) | FR7 |
| T8 | `yamllint adaptations.yaml` passes | FR4 |
| T9 | CI workflow YAML parses cleanly after edit (`python3 -c "import yaml; yaml.safe_load(open('.github/workflows/build.yml'))"`) | FR8–FR12 |
| T10 | `grep -c 'podman image inspect' .github/workflows/build.yml` returns >= 2 (two resolution steps) | FR8, FR9 |
| T11 | `grep -c 'BREW_IMAGE_SHA\|BASE_IMAGE_DIGEST' .github/workflows/build.yml` returns >= 1 | FR10 |
| T12 | `grep -c 'Lifecycle' .claude/HARNESS.md` returns >= 1 in Reference Repos table context | FR13 |
| T13 | HARNESS.md table row for fca contains `stable` | FR14 |
| T14 | HARNESS.md table row for ublue contains `active` | FR15 |
| T15 | HARNESS.md table row for bluefin contains `active` | FR16 |
| T16 | ADR file exists at expected path or ARCH_DECISIONS entry exists in AGENTS.md | FR17 |
| T17 | ADR contains `status: accepted` in YAML frontmatter | FR19 |
| T18 | ADR text includes rationale referencing project scale (~1.3MB, 3–4 submodules) | FR18 |
| T19 | ADR text mentions the directory-grouping alternative was considered and rejected | FR18 |

## 7. Slice Dependency Notes

All five slices are independent. The spec groups them in one document because
they share a source analysis and were decided together, but any slice can be
implemented and merged without waiting for the others.

- **R1 (S1) → R4 (S4)**: If S1 lands first, S4's table has no m2os row. If S4
  lands first, it lists m2os as `deprecated` and S1 removes it later. Both
  orderings are valid.
- **R3 (S3)**: Requires `skopeo` available in CI (Ubuntu runner already has it
  via `podman` — `skopeo` is a related package that may need explicit install).
- **R5 (S5)**: References R4's lifecycle column as part of the rationale for
  keeping flat structure, but does not depend on R4 being merged first.
