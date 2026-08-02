---
spec: docs/superpowers/specs/2026-08-02-submodule-recommendations.md
date: 2026-08-02
mode: spec
cartographer_model: DeepSeek V4 Pro
stories:
  - id: 1
    lens: [defaults]
    title: "YAML chosen for BOM without format discussion"
    disposition: accepted
    disposition_rationale: "YAML is the project's convention (yamllint, Python yaml.safe_load, frontmatter). Choosing the project default is a valid convention-over-configuration decision."
  - id: 2
    lens: [forces]
    title: "Optional upstream_commit trades precision for practicality"
    disposition: accepted
    disposition_rationale: "Forcing git-archaeology for files ported before the bluefin submodule existed would produce unreliable data. Optional with forked_at fallback is correct."
  - id: 3
    lens: [defaults, patterns]
    title: "GITHUB_ENV as the digest transport between CI steps"
    disposition: accepted
    disposition_rationale: "Platform-native mechanism. If CI migrates, the transport changes — that's inherent to platform coupling, not a design flaw."
  - id: 4
    lens: [patterns]
    title: "Bash default-expansion makes digest injection optional"
    disposition: accepted
    disposition_rationale: "${VAR:-} is the standard Null Object pattern for build args. Already proven by BREW_IMAGE_SHA."
  - id: 5
    lens: [consequences]
    title: "BOM enforcement deferred to periodic GC"
    disposition: accepted
    disposition_rationale: "Crawl-Walk-Run: ship the format now, add periodic GC for drift detection, promote to CI when stable. Consistent with project's existing harness constraint maturity."
  - id: 6
    lens: [patterns]
    title: "Symmetric ARG pattern extended from brew to base"
    disposition: accepted
    disposition_rationale: "Correct design: pin both images or neither. The BREW_IMAGE_SHA vs BASE_IMAGE_DIGEST naming inconsistency is acknowledged as a Gotcha candidate for AGENTS.md."
---

## Story #1 — YAML chosen for BOM without format discussion

**Source:** US2, FR4
**Lens:** defaults
**Refs:** O6

YAML is the project's convention — yamllint, Python yaml.safe_load, spec frontmatter. The BOM inherits this convention without explicit discussion because the project already validates YAML in CI.

## Story #2 — Optional upstream_commit trades precision for practicality

**Source:** US2 scenario 3
**Lens:** forces
**Refs:** O11

The `upstream_commit` field is the only optional field in the BOM schema. Requiring it would force git-archaeology on files ported before the bluefin submodule existed — producing unreliable data. Making it optional accepts that some provenance is lost but avoids bad data.

## Story #3 — GITHUB_ENV as the digest transport between CI steps

**Source:** US3 scenario 3, FR10
**Lens:** defaults, patterns
**Refs:** O5

`echo "BASE_IMAGE_DIGEST=${DIGEST}" >> $GITHUB_ENV` is the GitHub Actions idiom for step-to-step data flow. Platform-native, transparent to local dev.

## Story #4 — Bash default-expansion makes digest injection optional

**Source:** US3 scenarios 3-4, post-O1/O2
**Lens:** patterns
**Refs:** O1, O2

`FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}@${BASE_IMAGE_DIGEST:-}` — the `${VAR:-}` expansion makes the `@digest` suffix vanish when the ARG is empty (local dev) and pin when populated (CI). Null Object pattern applied to build arguments. Already proven by BREW_IMAGE_SHA.

## Story #5 — BOM enforcement deferred to periodic GC

**Source:** US2, Exclusions, post-O6
**Lens:** consequences
**Refs:** O6, O12

Crawl-Walk-Run: ship the BOM format now, add monthly GC enforcement for drift detection, promote to per-PR CI when the format stabilizes. Consistent with the project's existing harness constraint maturity (5 of 11 constraints currently unverified).

## Story #6 — Symmetric ARG pattern extended from brew to base

**Source:** US3 scenario 3, post-O1/O2
**Lens:** patterns
**Refs:** O1, O2, O5

The Containerfile's digest-pinning strategy is now uniform: both external images (brew, base) use identical ARG + CI injection + `${VAR:-}` fallback. Naming inconsistency noted: `BREW_IMAGE_SHA` (legacy) vs `BASE_IMAGE_DIGEST` (new) — future ARGs should use `*_DIGEST`.
