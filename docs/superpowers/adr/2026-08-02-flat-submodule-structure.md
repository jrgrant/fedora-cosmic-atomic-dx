---
date: 2026-08-02
status: accepted
source_analysis: docs/research/2026-08-02-submodule-strategy-analysis.md
---

# ADR: Keep Flat Submodule Structure

## Decision

The git submodule structure remains flat at the repo root — no directory
grouping such as `upstream/bluefin`, `upstream/ublue`, etc.

## Rationale

Directory grouping would break existing path references throughout the
project. Every script, CI workflow, and documentation reference that uses
a submodule path (e.g., `bluefin/build_files/...`) would need updating.
For a project of this size — ~1.3MB across 3 submodules (fca, ublue,
bluefin) — the cost of restructuring outweighs any clarity benefit.

The flat structure is adequate because:

1. **The project has only 3 submodules.** With so few, grouping by
   directory adds ceremony without solving a real navigation problem.
2. **HARNESS.md already communicates roles.** The Reference Repos table
   (with Lifecycle column: stable/active/deprecated) tells contributors
   at a glance which submodules are active dependencies and which are
   stable baselines — no directory convention needed.
3. **Path stability matters.** Build scripts, CI workflows, and Justfile
   targets reference submodule paths. Renaming a submodule's location
   would touch every one of those references and create merge conflicts
   across all active branches.

## Alternative Considered

**Directory grouping** (`upstream/bluefin`, `upstream/ublue`, etc.) was
considered as a way to visually distinguish upstream reference submodules
from first-party project content. Rejected because:

- Breaks all existing path references (scripts, CI, Justfile, docs)
- Creates merge conflicts across active branches
- Adds complexity (longer paths, nested git operations) without material
  benefit for a project with only 3 submodules
- HARNESS.md documentation achieves the same communication goal without
  structural changes

## Consequences

- Submodules remain at `fca/`, `ublue/`, `bluefin/` — no path changes
- HARNESS.md Reference Repos table (with Lifecycle column) is the
  canonical source for submodule role expectations
- If the project grows to 6+ submodules, this decision should be
  revisited — the cost-benefit calculus changes at that scale
