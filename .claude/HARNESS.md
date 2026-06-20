# Harness — Atomic (FCA Developer Experience)

## Context

### Stack

- **Primary languages**: Shell (bash), YAML, Markdown, JSON
- **Build system**: None (configuration/scripting project)
- **Test framework**: shellcheck, yamllint, markdownlint-cli2, Python json/yaml validation
- **Container strategy**: OCI images via Containerfile/Dockerfile (target: Fedora Atomic OCI overlays)

### Conventions

- **Naming**: lowercase-hyphenated for files and scripts; YAML configs follow the source-of-truth repo conventions (bluefin/FCA)
- **File structure**: Root holds harness config and project output; reference repos (m2os, ublue, bluefin, fca) are git submodules — read-only
- **Error handling**: Shell scripts use `set -euo pipefail`; every script returns a meaningful exit code
- **Documentation**: Markdown with narrative preambles; every script has a header comment explaining its purpose

### Reference Repos

| Submodule | Upstream | Purpose |
| --------- | -------- | ------- |
| `m2os/`   | m2Giles/m2os | Current OS — source of pain, diff reference for what's missing |
| `ublue/`  | ublue-os/main | Universal Blue base — parent of bluefin, shared infrastructure |
| `bluefin/` | ublue-os/bluefin | Bluefin — the target DX, source of truth for dev tooling |
| `fca/`    | fedora atomic-desktops/config | Fedora COSMIC Atomic — our stable base |

---

## Constraints

### Consistent formatting

- **Rule**: All shell scripts must pass shellcheck without errors; YAML must parse clean; Markdown must pass markdownlint
- **Enforcement**: deterministic
- **Tool**: `scripts/ai-literacy-check.sh`
- **Scope**: commit

### No secrets in source

- **Rule**: No API keys, tokens, passwords, or private keys may appear in committed source files
- **Enforcement**: deterministic
- **Tool**: gitleaks detect --source . --no-banner --exit-code 1
- **Scope**: commit

### Spec-first commit ordering

- **Rule**: Every PR that changes application behaviour must include spec updates before or alongside implementation changes
- **Enforcement**: agent
- **Tool**: harness-enforcer
- **Scope**: pr

### PRs have adjudicated objections

- **Rule**: Every feature or behaviour-change PR must have a spec-mode objection record with all dispositions resolved
- **Enforcement**: agent
- **Tool**: harness-enforcer
- **Scope**: pr

---

## Garbage Collection

### Stale documentation check

- **What it checks**: Whether PROBLEM.md and README reflect the current project state
- **Frequency**: weekly
- **Enforcement**: agent
- **Tool**: harness-gc agent
- **Auto-fix**: false

### Submodule staleness

- **What it checks**: Whether reference submodules have drifted significantly from their upstream remotes
- **Frequency**: weekly
- **Enforcement**: deterministic
- **Tool**: `git submodule foreach 'git fetch && git diff --stat HEAD..origin/main | wc -l'`
- **Auto-fix**: false

---

## Status

- Constraints enforced: 3/4
- Garbage collection active: 2/2
