---
name: codebase-analysis
description: Use when the user needs systematic internal codebase research — "find architectural contradictions in this codebase", "identify duplicated logic across modules", "audit security patterns in the Containerfile build chain", "trace the impact of changing X across all files", "find inefficiencies in the build pipeline" — covers structural analysis, pattern detection, dependency mapping, and change impact tracing. Scoped to the workspace only: no web access, no external sources.
---

# Codebase Analysis (Internal Research)

## Overview

Internal research is structural analysis of the codebase — finding patterns,
contradictions, duplication, security gaps, and inefficiencies within the
files and directories already present. It is the complement of external
research (web gathering and synthesis, covered by `technical-research`).

The two are separate activities with separate tool sets, separate failure
modes, and separate adversarial review categories. A single agent should
not do both: the context required to search the web competes with the
context required to hold a mental model of the codebase structure. Splitting
them keeps each agent's context window focused.

**This skill does NOT cover:** web search, external documentation, upstream
source reading, or any information that requires leaving the workspace.
Those are the domain of `technical-research`.

## When to Use Codebase Analysis

| Situation | Signal |
| ----------- | -------- |
| Architectural audit | "Does this codebase follow its stated layering conventions?" |
| Duplication detection | "Are there two implementations of the same logic?" |
| Security pattern review | "Are all shell scripts following the same hardening practices?" |
| Change impact analysis | "If I change X, what else breaks?" |
| Build pipeline efficiency | "Are there redundant steps or unnecessary rebuilds?" |
| Convention compliance | "Does every script pass shellcheck? Are all YAML files valid?" |
| Dependency graph analysis | "What depends on what, and are there circular dependencies?" |
| Dead code detection | "Is this function/variable/file still referenced anywhere?" |

## Context Isolation — Why It Matters

The codebase-analyst has **no web tools**. It cannot fetch pages, search
GitHub, or read external documentation. This is deliberate, not a limitation.

A researcher that can search the web while analyzing the codebase will:
- Chase external rabbit holes instead of finishing structural analysis
- Confuse "what the docs say should happen" with "what the code actually does"
- Fill its context window with external content, displacing codebase structure

By restricting to workspace-only tools, the analyst is forced to read the
code as it is, not as it's documented. The research note it produces is an
honest description of the codebase — not a synthesis of the codebase plus
external documentation that may be stale or wrong.

**When the analyst needs external context**, it does not fetch it itself.
It flags an "External Research Needed" item in its note and stops. The
orchestrator then dispatches `technical-researcher` against that specific
question. See [Handoff to External Research](#handoff-to-external-research).

## The Four-Phase Analysis Loop

```
┌──────────────────────────────────────────────────────┐
│            CODEBASE-ANALYST (workspace only)          │
│                                                      │
│  1. Scope  →  2. Map  →  3. Inspect  →  4. Report    │
│                                                      │
│  Tools: Read, Glob, Grep, semantic_search,            │
│         file_search, grep_search                      │
│  No: fetch_webpage, github_*, Bash (write)            │
└──────────────────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│              REVIEWER (external, adversarial)          │
│  research-reviewer — codebase mode                    │
│  Checks: code-evidence mismatch, scope creep,         │
│          missed counterexamples, pattern overfitting   │
└──────────────────────────────────────────────────────┘
```

### Phase 1: Scope the Analysis

Define what part of the codebase is under analysis, what lens is applied,
and what success looks like.

```markdown
## Analysis Scope

**Target:** [directory, file glob, or conceptual boundary — e.g. "all shell
scripts under build_files/" or "the dependency graph between fca/ and
system_files/"]

**Lens:** [what we're looking for]
- architectural-contradiction
- duplication
- security-pattern
- change-impact
- efficiency
- convention-compliance
- dependency-graph
- dead-code

**Success criteria:**
- [ ] [concrete, falsifiable — "every .sh file checked against shellcheck"]
- [ ] ["all COPY directives in Containerfile traced to their sources"]
```

### Phase 2: Map the Territory

Before inspecting details, build a structural map. This prevents diving
into a single file and missing the broader pattern.

#### Mapping techniques by lens

| Lens | Mapping technique |
| ---- | ----------------- |
| architectural-contradiction | Read architecture docs (AGENTS.md, CLAUDE.md, HARNESS.md), then list all modules/directories and their stated responsibilities |
| duplication | `grep_search` for function names, script patterns, or configuration blocks across the target scope |
| security-pattern | List all entry points (scripts, Containerfile instructions, configuration files) and their privilege context |
| change-impact | `vscode_listCodeUsages` on the symbol being changed; trace every reference |
| efficiency | List all build steps/scripts in execution order; identify inputs and outputs of each |
| convention-compliance | List all files matching the target glob; check each against the convention |
| dependency-graph | `grep_search` for imports, `source`, `. /`, `COPY --from`, `FROM` across the target |
| dead-code | `vscode_listCodeUsages` on every public symbol; flag anything with zero references |

#### Map output

Produce a structured inventory before any detailed inspection:

```markdown
## Territory Map

### Modules / Directories
| Path | Stated purpose | Files | Dependencies |
|------|---------------|-------|-------------|

### Entry Points
| File | Type | Privilege context | Called by |
|------|------|------------------|-----------|

### Cross-references
[Mermaid diagram or text description of the dependency graph]
```

### Phase 3: Inspect

With the map in hand, inspect each finding. For every claim in the report,
cite specific file:line evidence.

#### Inspection rules

1. **Cite evidence, not impressions.** "The build script is inefficient" is
   an impression. "`04-packages.sh` runs `dnf install` three times in
   separate transactions (lines 12, 34, 56) where a single transaction
   would work" is evidence.

2. **Test the counter-hypothesis.** For every claim, ask: "What would prove
   this wrong?" Then search for that evidence. If you find a counterexample,
   report it — it's as valuable as the finding.

3. **Scope discipline.** If a finding requires information outside the
   workspace, do not speculate. Flag it as "External Research Needed" and
   stop investigating that thread.

4. **Version awareness.** The codebase at HEAD is the ground truth. Do not
   assume behaviour based on file names, comments, or what "should" happen.

### Phase 4: Report

Produce a structured analysis note. Every claim carries a file:line citation.

```markdown
---
date: YYYY-MM-DD
target: [directory/glob]
lens: [analysis lens]
status: complete | in-progress
findings_count: N
origin: codebase-analyst
external_research_needed: true | false
---

# [Analysis Title]

## Scope
[From Phase 1]

## Territory Map
[From Phase 2]

## Findings

### F1: [Headline]
**Severity:** critical | high | medium | low | info
**Evidence:** `path/to/file:12-15` — [what the code does]
**Why it matters:** [impact on correctness, security, maintainability, or
  performance]
**Counter-hypothesis tested:** [what we checked to avoid a false positive]

### F2: [Headline]
...

## Patterns Observed
[Cross-cutting observations that span multiple findings — "three of the
five build scripts share this anti-pattern..."]

## Explicitly Checked and Found Clean
- [Thing we inspected and found no issue with. This is data — it prevents
   re-auditing the same thing.]

## External Research Needed
- [ ] [Question that requires external information — the analyst stops here]
- [ ] [Another question for the technical-researcher]
```

## Handoff to External Research

When the analyst encounters a question it cannot answer from the codebase
alone, it does not switch tools and start searching the web. It:

1. Records the question in the "External Research Needed" section
2. Sets `external_research_needed: true` in the frontmatter
3. Completes the rest of the analysis it CAN do from the codebase
4. Returns the note

The orchestrator (or user) then dispatches `technical-researcher` against
the specific questions listed. The researcher receives:
- The analysis note (for context on why the question matters)
- The specific external research question

**This is the context isolation mechanism.** The analyst never sees web
content. The researcher never needs to hold the full codebase structure
in its context window. Each agent's context is scoped to its domain.

### Handoff scenarios

| Analyst finds | Researcher investigates |
| ------------- | ----------------------- |
| "This workaround in `18-workarounds.sh` references a bug — is it fixed upstream?" | Search for the upstream bug tracker, release notes, fix version |
| "We're using pattern X from FCA, but Bluefin uses Y — what's the difference?" | Research the trade-offs between X and Y from documentation and community sources |
| "This COPR repo is pinned to a specific commit — is there a newer version?" | Check the COPR repo for releases, changelogs, known issues |
| "Containerfile uses `--flag` that is not in the podman man page we have" | Search for the flag in newer podman versions, release notes, or issues |
| "Script references a kernel module — is it still maintained?" | Check kernel.org, module maintainer status, deprecation notices |

## Anti-Patterns

| Anti-pattern | Problem | Fix |
| ------------ | ------- | --- |
| Web-search during analysis | Context pollution; confuses code reality with documentation claims | Flag as External Research Needed; do not switch tools |
| Impression without citation | "This is wrong" without file:line is unreviewable | Every claim carries a file:line reference |
| No counter-hypothesis test | Confirmation bias — finding what you expected to find | For each finding, document what would disprove it and check |
| Scope creep into implementation | Analysis turns into "here's how to fix it" | Analysis describes what IS; implementation is a separate pipeline |
| Single-file deep-dive | Missing the structural pattern by focusing on one file | Phase 2 (map) must precede Phase 3 (inspect) |

## Tool Mapping

| Analysis phase | Copilot tool |
| -------------- | ------------ |
| Map structure | `list_dir`, `file_search`, `Glob` |
| Find patterns | `grep_search`, `semantic_search` |
| Trace dependencies | `vscode_listCodeUsages`, `grep_search` |
| Read evidence | `read_file` |
| Structural search | `semantic_search` (natural language query over codebase) |

**Deliberately excluded:** `fetch_webpage`, `github_text_search`,
`github_repo`. These belong to `technical-researcher`.
