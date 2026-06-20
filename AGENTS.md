# Compound Learning

<!-- This file is the project's persistent memory across AI sessions.
     It accumulates patterns, gotchas, and decisions so that each session
     builds on what previous sessions learned — rather than rediscovering
     the same things from scratch.

     IMPORTANT: This file is often generated or updated by LLM agents.
     Review new entries with the same scepticism you would apply to any
     generated content. Entries should reflect observed reality in the
     codebase, not aspirational conventions. -->

## STYLE

<!-- Patterns and idioms that work well in this codebase. -->

## GOTCHAS

<!-- Traps, surprises, and non-obvious constraints. Initially empty — entries
     accumulate as the pipeline discovers them. -->

- **FCA base ≠ Silverblue**: The FCA base image lacks directories and service
  units present in UBlue/Bluefin's Silverblue-derived base. Always:
  - Guard `systemctl enable` with `|| true` — services may not exist
  - `mkdir -p` before writing to `/usr/share/ublue-os/`
  - Never change `ID` in `os-release` — it must stay `fedora` for dnf5 COPR
    chroot resolution
  - The `_copr_ublue-os-akmods.repo` file may not exist — guard any sed on it

## ARCH_DECISIONS

- **Decision**: Use git submodules for reference repos (m2os, ublue, bluefin, fca) rather than in-tree copies.
  **Reason**: These are read-only references — we read and diff them but never modify. Submodules pin a specific commit, making diffs deterministic.
  **Alternatives considered**: shallow clones (rejected — no commit pinning), vendored copies (rejected — bloats repo, drifts).

- **Decision**: Project root holds harness config + output artifacts; submodules hold references.
  **Reason**: Clean separation between our work product and upstream sources. The harness (CLAUDE.md, HARNESS.md, agents, CI) is first-class project content.

## TEST_STRATEGY

- Shell scripts: validate with `shellcheck` (all scripts under `scripts/`)
- YAML files: structural validation with Python `yaml.safe_load`
- Markdown: `markdownlint-cli2` for consistency
- JSON: Python `json.load` structural check
- CI runs all of the above on every PR

## DESIGN_DECISIONS

<!-- Key design decisions and their rationale. -->
