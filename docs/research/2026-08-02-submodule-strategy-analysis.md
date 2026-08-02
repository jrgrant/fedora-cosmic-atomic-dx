---
date: 2026-08-02
target: submodule strategy
lens: architectural-contradiction, dependency-graph, efficiency
origin: codebase-analyst
status: complete
findings_count: 5
external_research_needed: false
---

# Submodule Strategy Analysis

## Scope

**Target:** All git submodules (bluefin, m2os, ublue, fca) and their usage in
build scripts, documentation, and CI.

**Lens:** architectural-contradiction, dependency-graph, efficiency

**Success criteria:**
- [x] Each submodule's purpose is clear and justified
- [x] Dependencies between submodules and our build are mapped
- [x] Redundancy, dead weight, and conflict potential identified
- [x] Bill of materials management strategy recommended

## Territory Map

### Submodule Inventory

| Submodule | Upstream | Size | Ref count | Role |
|-----------|----------|------|-----------|------|
| `bluefin/` | ublue-os/bluefin | 416K | 19 files | Target DX — build scripts adapted from here, justfile patterns, system config |
| `ublue/` | ublue-os/main | 268K | 18 files | Parent of bluefin — brew image source, CI patterns, mostly docs/specs refs |
| `m2os/` | m2Giles/m2os | 368K | 2 files | Legacy OS — diff reference, no active build usage |
| `fca/` | fedora-atomic-desktops/config | 268K | 4 files | Base image config — defines what ships in cosmic-atomic:44 |

### Dependency Graph

```
fca (base image config)
 │
 ├──→ Containerfile: FROM quay.io/fedora-ostree-desktops/cosmic-atomic:44
 │
 ublue (parent infrastructure)
 │
 ├──→ Containerfile: FROM ghcr.io/ublue-os/brew:latest
 ├──→ CI patterns (workflow structure)
 │
 bluefin (target DX)
 │
 ├──→ build_files/base/03-install-kernel-akmods.sh (adapted)
 ├──→ build_files/base/04-packages.sh (adapted)
 ├──→ build_files/base/19-initramfs.sh (adapted)
 ├──→ build_files/dx/00-dx.sh (adapted)
 ├──→ build_files/shared/build.sh (adapted)
 ├──→ system_files/ patterns (ujust, services)
 │
 m2os (legacy — no active build dependency)
```

## Findings

### F1: m2os is dead weight

**Severity:** medium
**Evidence:** `grep -rl m2os build_files/ system_files/ scripts/` returns zero
results outside docs/. The submodule is 368K of code with no build-time or
runtime dependency. All migration diffs have been extracted into
`docs/research/`.
**Why it matters:** Submodule checkout time, CI clone overhead, and cognitive
load on new contributors who see "m2os" and wonder if it's still relevant.
**Counter-hypothesis tested:** Searched all build scripts, Containerfile, and
system_files for m2os references — none found outside documentation.

### F2: ublue and bluefin overlap — parent-child redundancy

**Severity:** low
**Evidence:** ublue-os/main is the parent repo of ublue-os/bluefin. Our
primary build dependency is bluefin (build scripts, dx patterns). ublue
provides the brew image (`ghcr.io/ublue-os/brew:latest`) and CI workflow
patterns. 17 of 18 ublue references are in docs/specs from the Phase 2
pipeline, not in active build code.
**Why it matters:** Both submodules are checked out but the build dependency
is asymmetric — bluefin carries the patterns we adapt; ublue provides the
brew layer via OCI image (not source). The submodule is used primarily as
documentation, not as build source.
**Counter-hypothesis tested:** Checked if any build script `source`s from
ublue directly — none do. The CI workflow borrows structural patterns but
doesn't execute ublue code.

### F3: No bill of materials — provenance tracking is implicit

**Severity:** high
**Evidence:** `build_files/base/03-install-kernel-akmods.sh:3` says "Adapted
from bluefin/build_files/base/03-install-kernel-akmods.sh" — a comment, not
structured metadata. Other adapted files (04-packages.sh, 19-initramfs.sh,
00-dx.sh, build.sh) have no provenance comments at all. There is no manifest
tracking which of our files are adapted from bluefin, which are original, and
what versions they were forked from.
**Why it matters:** When bluefin upstream changes, we have no structured way
to determine which of our files need review. The monthly GC rule helps but
requires human judgment for every file. A BOM would let CI flag "bluefin
changed X — our adapted copy of X may need updating."
**Counter-hypothesis tested:** Searched for any YAML/JSON manifest tracking
adaptations — none found.

### F4: Upstream version pinning is inconsistent

**Severity:** medium
**Evidence:** `.gitmodules` pins submodules by commit hash (git default), but
our Containerfile uses mutable tags: `quay.io/fedora-ostree-desktops/cosmic-atomic:44`,
`ghcr.io/ublue-os/brew:latest`. The `:44` tag floats with FCA rebuilds;
`:latest` floats with every brew push. Only the submodules are pinned. The
OCI image dependencies are not.
**Why it matters:** A rebuild with the same commit can produce a different
image if the base image or brew layer changed. Reproducibility depends on
registry state, not just source state.
**Counter-hypothesis tested:** Checked Containerfile for digest pins — none
present. Checked CI for digest injection — not configured.

### F5: Submodule structure is flat — no grouping by role

**Severity:** low
**Evidence:** Four submodules at root level with no grouping. bluefin and
ublue are related (parent-child in the ublue-os org). fca is the base.
m2os is legacy. The flat structure treats all four as equal peers when they
have fundamentally different roles.
**Why it matters:** New contributors see four submodules and assume equal
importance. The flat structure doesn't communicate that m2os is deprecated
and bluefin/ublue are a family.
**Counter-hypothesis tested:** Considered whether grouping by directory
(e.g., `upstream/bluefin`, `upstream/ublue`) would help — it would make
paths longer and break existing references. Grouping by role is better
done in HARNESS.md (already documented there).

## Patterns Observed

- **Adaptation pattern**: Our build scripts start from bluefin originals and
  diverge. Comments document the divergence in some files (03-install-kernel)
  but not others. This is an informal fork pattern.
- **Reference-only pattern**: fca and m2os are never executed or included in
  build output. They exist solely for human reference and diff comparison.
  The GC rules check them for staleness but nothing depends on them at build
  time.
- **OCI bridge pattern**: ublue provides the brew image via OCI registry, not
  via source. The submodule exists for CI patterns and documentation, not for
  build-time code inclusion.

## Recommendations

### R1: Remove m2os submodule

The migration is complete. All diff knowledge has been extracted into
`docs/research/`. The submodule adds checkout time and cognitive load with
zero build dependency.

**Action:** `git submodule deinit m2os && git rm m2os`. Update HARNESS.md
reference table. Move "source of pain" context to a doc if needed.

### R2: Add bill of materials (adaptations.yaml)

Create `adaptations.yaml` tracking every file adapted from upstream:

```yaml
adaptations:
  - file: build_files/base/03-install-kernel-akmods.sh
    upstream: bluefin/build_files/base/03-install-kernel-akmods.sh
    forked_at: 2026-06-20
    upstream_commit: 742b3b7
    notes: "Desktop-agnostic kernel swap. Diverged: COSMIC-specific cleanup, no ZFS kernel pin."
  - file: build_files/base/04-packages.sh
    upstream: bluefin/build_files/base/04-packages.sh
    forked_at: 2026-06-20
    notes: "Stripped GNOME packages, added COSMIC equivalents."
  # ... etc
```

CI can diff upstream changes against this manifest and flag files needing
review. This makes the monthly GC rule automatable.

### R3: Pin OCI base images by digest in CI

Add digest injection to the CI workflow. Containerfile keeps mutable tags
for local development. CI resolves tags to digests and injects them:

```yaml
- name: Resolve base image digest
  run: |
    DIGEST=$(skopeo inspect docker://quay.io/fedora-ostree-desktops/cosmic-atomic:44 --format '{{.Digest}}')
    echo "BASE_IMAGE_DIGEST=${DIGEST}" >> $GITHUB_ENV
```

This makes CI builds reproducible without sacrificing local dev convenience.

### R4: Document submodule roles more explicitly

HARNESS.md already has the reference table. Add a "lifecycle" column:

| Submodule | Role | Lifecycle |
|-----------|------|-----------|
| `fca/` | Base image config | Stable — tracks fedora-atomic-desktops |
| `ublue/` | Parent infrastructure | Active — brew image, CI patterns |
| `bluefin/` | Target DX source | Active — primary adaptation source |
| `m2os/` | Legacy reference | Deprecated — remove |

### R5: Keep flat submodule structure

The flat structure is fine given the project's size (~1.3MB total across 4
submodules). Grouping by directory would break path references and add
complexity without benefit. HARNESS.md documentation is sufficient for
communicating roles.

## External Research Needed

None — all findings are from codebase analysis.
