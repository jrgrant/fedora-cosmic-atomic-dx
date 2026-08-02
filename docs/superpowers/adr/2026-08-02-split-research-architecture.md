---
date: 2026-08-02
status: accepted
---

# ADR: Split Research Architecture — Internal vs External with Adversarial Review

## Context

The project needed a research capability. The initial design was a single
`technical-researcher` agent that could both search the web and analyze the
codebase. During review, two gaps were identified:

1. **No adversarial review.** The researcher self-evaluated (Phase 5 gap-check),
   which catches typos but not confirmation bias, source misreading, or unstated
   assumptions. The main orchestrator pipeline already had `advocatus-diaboli`
   for this — the research pipeline needed the equivalent.

2. **No context isolation.** A single agent with both web and codebase tools
   would chase external tangents instead of finishing structural analysis, and
   would confuse "what the docs say" with "what the code does." The two
   activities have different tools, failure modes, and evaluation criteria.

## Decision

Split research into three agents with strict context isolation:

```
codebase-analyst          technical-researcher       research-reviewer
(internal only)           (external only)             (adversarial, 2 modes)
workspace tools only      web tools only              reads notes + sources/code
four-phase loop           five-phase loop             six categories per mode
```

### Context Isolation Mechanism

Each agent is dispatched fresh — no shared context window, no shared state.
The analyst has no web tools. The researcher has web tools but its `Read` and
`grep_search` are restricted to reading handoff notes and existing research,
not structural codebase exploration. The reviewer sees only the finished note
and its cited evidence.

The handoff: when the analyst hits a codebase boundary (a question it can't
answer from code alone), it writes an "External Research Needed" item and stops.
The orchestrator dispatches the researcher against that specific question. The
researcher reads the analyst's note for context but never holds codebase
structure in its context window.

### Adversarial Review (Two Modes)

The reviewer has two mode-specific category sets, mirroring `advocatus-diaboli`'s
spec/code modes:

- **External mode** (reviewing `technical-researcher` notes): source-quality,
  claim-source-mismatch, assumption-detection, confidence-inflation,
  gap-analysis, structural-quality
- **Codebase mode** (reviewing `codebase-analyst` notes): code-evidence-mismatch,
  missed-counterexample, pattern-overfitting, scope-creep,
  impression-without-citation, structural-quality

All dispositions are human-only — no agent writes `accepted`/`deferred`/`rejected`.

## Alternatives Considered

| Alternative | Rejected because |
|-------------|-----------------|
| Single agent with internal/external modes | Mode-switching within one context window doesn't solve context pollution. The agent would still hold both codebase and web content simultaneously |
| No adversarial review (self-evaluation only) | Contradicts the project's established pattern. The main pipeline already proved that self-review is necessary but insufficient |
| Three-mode reviewer (external, codebase, combined) | Combined mode would need both category sets simultaneously, bloating the reviewer's context and diluting scrutiny |

## Consequences

- **Positive:** Each agent's context window is focused on one domain. The
  analyst never chases web tangents. The researcher never confuses docs with
  code. The reviewer's scrutiny is sharper because it evaluates against a
  specific evidence type (sources or code), not both at once.
- **Negative:** Two dispatches instead of one for questions that span both
  domains. The handoff adds latency. Mitigated by the fact that most research
  questions are either internal or external, not both.
- **Negative:** Three agents to maintain instead of one. Mitigated by the
  shared skill/reviewer infrastructure — skills define methodology, agents
  define tool boundaries and charters.

## References

- Anthropic (2024). "Building Effective Agents" — evaluator-optimizer and
  orchestrator-workers patterns
- Yao et al. (2023). "ReAct: Synergizing Reasoning and Acting in Language
  Models" — the Thought→Action→Observation loop used in the five-phase
  research cycle
- Project's existing `advocatus-diaboli` agent — the adversarial review
  pattern this design mirrors
