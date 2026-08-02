---
name: technical-research
description: Use when the user needs systematic technical research — "research how X works", "find the best approach for Y", "investigate upstream changes in Z", "what are the options for..." — covers search strategy, source evaluation, structured synthesis, and iterative refinement. Applies the evaluator-optimizer pattern (Anthropic, 2024) to research: plan searches, gather sources, evaluate quality, synthesise findings, and refine gaps.
---

# Technical Research

## Overview

Technical research is not a single search-and-summarise step. It is an
iterative process of formulating questions, gathering sources, evaluating
their quality, synthesising findings, and identifying gaps that need
further investigation. This skill structures that process for AI-assisted
research.

The methodology draws on two well-established agent patterns:

- **Evaluator-optimizer** (Anthropic, 2024): each round of research
  produces findings, which are evaluated against the research question;
  gaps trigger a refined round. This is the same pattern that makes
  iterative translation and complex search tasks effective.
- **ReAct** (Yao et al., 2023): reasoning and acting interleaved —
  think about what to search, search, observe the results, think about
  what they mean, search again. The `Thought → Action → Observation`
  loop prevents research from drifting into aimless browsing.

This skill does **not** cover code implementation, architecture
decisions, or spec writing. It produces research notes that feed those
downstream activities.

## When to Use Technical Research

| Situation | Signal |
| ----------- | -------- |
| Upstream dependency change | A new release of a key dependency needs impact analysis |
| Technology selection | Choosing between multiple libraries, tools, or approaches |
| Bug investigation | A surprising behaviour needs root-cause analysis from external sources |
| Integration design | Understanding how two systems interact before designing the glue |
| Security advisory response | A CVE or advisory needs context: affected versions, mitigation, exploitability |
| Documentation gap | Official docs are incomplete and community knowledge is scattered |

**Sizing heuristic:** If the answer can be found in a single well-known
page, do not use this skill — just fetch the page. Use this skill when
the answer requires synthesising information from multiple sources,
evaluating conflicting claims, or tracking down information that is not
in a single canonical location.

## The Five-Phase Research Loop

Each phase produces an artefact that feeds the next. The loop repeats
until the evaluator step signals completion. After the researcher finishes,
an adversarial review by `research-reviewer` — an independent agent with
fresh context — validates the findings before they are acted on.

```
┌─────────────────────────────────────────────────────┐
│                  RESEARCHER (internal)               │
│  1. Frame  →  2. Search  →  3. Evaluate  →  4. Synthesise
│                                     │                │
│                                     ▼                │
│                              5. Gap-check  ←─────────┘
│                                     │                │
│                              ┌──────┴──────┐         │
│                              │  No gaps?    │         │
│                              │  → Publish   │         │
│                              │  Gaps found? │         │
│                              │  → Reframe   │         │
│                              └──────────────┘         │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              REVIEWER (external, adversarial)         │
│  6. Adversarial Review — independent agent with      │
│     fresh context challenges findings, sources,      │
│     assumptions, confidence, and gaps                │
│                         │                            │
│                  ┌──────┴──────┐                     │
│                  │  Human       │                     │
│                  │  disposition │                     │
│                  └──────────────┘                     │
└─────────────────────────────────────────────────────┘
```

Phases 1–5 are internal to the researcher — self-evaluation catches
typos, obvious omissions, and incomplete searches. Phase 6 is external
and adversarial — `research-reviewer` catches structural confirmation
bias, source misreading, unstated assumptions, and confidence inflation
that the researcher cannot see because it made them. The same agent
should not evaluate its own work.

### Phase 1: Frame the Research Question

A well-framed question determines what you search for and how you
evaluate results. A bad question wastes cycles on irrelevant sources.

**Rule:** The question must be specific enough to evaluate an answer
against. "Research container runtimes" is too broad. "What are the
differences between crun and runc for rootless Podman on Fedora 42?"
can be answered.

Produce a framing block:

```markdown
## Research Question
[One precise question — what are we trying to learn?]

## Context
[Why this matters — what decision depends on the answer?]

## Scope
- In scope: [boundaries of the investigation]
- Out of scope: [deliberate exclusions]

## Success Criteria
- [ ] Criterion 1 — what would make this research "done"?
- [ ] Criterion 2
```

### Phase 2: Search Strategy

Search is not one query. It is a strategy that combines multiple angles,
source types, and query formulations.

#### Query formulation rules

1. **Start specific, broaden if empty.** A specific query that returns
   nothing tells you the answer isn't obvious. A broad query that returns
   noise tells you nothing.
2. **Use the domain's vocabulary.** Search for terms the community uses,
   not your translation of them. "COSMIC keyring integration" not "how
   COSMIC stores passwords".
3. **Multiple query angles.** The same fact lives under different
   descriptions. Try:
   - The problem statement ("COSMIC gnome-keyring not persisting")
   - The technology name ("XDG Desktop Portal secrets backend")
   - The symptom ("Chrome cookies not saving COSMIC")
   - The solution pattern ("Workaround for gnome-keyring UseIn filter")
   - The authoritative source ("freedesktop.org secret-portal spec")

#### Source tiering (from the Model Cards discipline)

Apply the same tiered-source strategy used in model-card research:

| Tier | Source type | Trust weight | When to use |
| ---- | ----------- | ------------ | ----------- |
| 1 | Official docs, specs, source code | Highest | Always check first |
| 2 | Maintainer blog posts, release notes, commit messages | High | Fill gaps tier 1 leaves |
| 3 | Community forums, Stack Overflow, GitHub issues | Medium | Practical experience, edge cases |
| 4 | AI-generated summaries, LLM knowledge | Lowest | Orientation only — verify against tiers 1–3 |

**Critical rule: Tier 4 (LLM knowledge) is orientation, not evidence.**
Version numbers, API signatures, and "how it works" descriptions from
LLM training data are stale by construction. Always verify against a
tier 1–3 source. Never cite LLM knowledge as a finding.

### Phase 3: Source Evaluation

For each source found, evaluate before synthesising. Not every page that
matches a search is a source worth citing.

#### Evaluation checklist

- [ ] **Authority:** Who wrote it? Are they a maintainer, a user, or a
  summariser?
- [ ] **Currency:** When was it published or last updated? Is it still
  accurate for the versions we care about?
- [ ] **Specificity:** Does it address our exact question, or a
  neighbouring one?
- [ ] **Corroboration:** Can another source (different author, different
  site) confirm the key claim?
- [ ] **Conflict:** Does it contradict another source? (Flag this — it
  is data, not noise.)

#### Confidence annotation

Annotate each source with a confidence level:

| Confidence | Meaning |
| ---------- | ------- |
| **confirmed** | Two or more independent tier 1–2 sources agree |
| **likely** | One tier 1–2 source or multiple tier 3 sources agree |
| **tentative** | Single tier 3 source, or sources conflict |
| **unverified** | Tier 4 only — needs verification before use |

### Phase 4: Synthesise

Synthesis is not a list of sources. It is an answer to the research
question, supported by sources, with confidence disclosed.

#### Synthesis structure

```markdown
## Synthesis: [Research Question]

### Finding 1: [Headline claim]
**Confidence:** confirmed | likely | tentative
**Sources:** [tier]: [link or reference]
**Detail:** [what we learned, in our own words]
**Caveat:** [any limitation, version constraint, or uncertainty]

### Finding 2: [Headline claim]
...

### Open Questions
- [ ] [Question that emerged during research but is out of scope]
- [ ] [Question the sources didn't answer]

### Explicitly Not Found
- [Thing we looked for and didn't find. This is data — it tells
   the next researcher not to look again.]
```

### Phase 5: Gap Check (Evaluator Step)

After synthesis, evaluate whether the research question is answered.

#### Gap-check questions

1. **Completeness:** Does every success criterion from Phase 1 have a
   finding that addresses it?
2. **Conflict resolution:** Are any findings contradicted by other
   findings? If so, is the conflict explained or flagged?
3. **Version coverage:** Do the findings cover the versions/frameworks
   in scope?
4. **Alternative interpretations:** Could a reasonable person read the
   same sources and reach a different conclusion? If so, why did we
   choose this interpretation?

**If gaps found:** Return to Phase 1 with a refined question targeting
the gap. The second round is narrower and faster because you now know
what you don't know.

**If no gaps:** The researcher's internal QC is complete. The research
note is ready for adversarial review (Phase 6). Phase 5 is self-evaluation
— it catches omissions and errors the researcher can see. It does not
catch confirmation bias, source misreading, or unstated assumptions.

### Phase 6: Adversarial Review (External Gate)

Phase 5 is internal QC. Phase 6 is the real gate: an independent agent
(`research-reviewer`) with fresh context reads the research note and
produces structured objections across six categories:

1. **Source quality** — are the sources what the note claims?
2. **Claim-source mismatch** — does the source actually support the claim?
3. **Assumption detection** — what does the note assume without stating?
4. **Confidence inflation** — is the label justified by the sources?
5. **Gap analysis** — what should the note have found but didn't?
6. **Structural quality** — is the note well-formed as a research artefact?

The reviewer is dispatched fresh, not chained from the researcher. It sees
only the finished note and its cited sources — not the researcher's search
history, internal reasoning, or discarded leads. This forces evaluation of
what was actually produced, not what was intended.

The reviewer produces an objection record at
`docs/research/objections/<YYYY-MM-DD>-<slug>-review.md`. The human
disposes each objection (`accepted`/`deferred`/`rejected`) — no agent
writes dispositions.

**If critical or high-severity objections are accepted:** The research
note should be revised before any decision depends on it.

**Why adversarial review matters for research.** The researcher spent
time finding sources that confirm its framing. It read those sources
through the lens of its own question. It cannot reliably detect when it
misread a source, over-extrapolated a claim, or assumed a version it
didn't state. A fresh agent with no investment in the findings can.
This is the same principle as `advocatus-diaboli` reviewing a spec:
self-review is necessary but insufficient.

## Output: The Research Note

A completed research cycle produces a research note at
`docs/research/<YYYY-MM-DD>-<slug>.md` with this structure:

```markdown
---
date: YYYY-MM-DD
question: [one-line research question]
status: complete | in-progress | abandoned
confidence: high | medium | low
sources_consulted: N
rounds: N
---

# [Research Question]

## Framing
[From Phase 1 — the question, context, scope, and success criteria]

## Sources
[Numbered list of sources with tier and confidence annotation]

## Synthesis
[From Phase 4 — findings with confidence, sources, detail, caveats]

## Gap Check
[From Phase 5 — what was checked, what's still open, what wasn't found]

## Decisions
[If this research informed a decision, record it here]
- **Decision:** [what was decided]
- **Rationale:** [why, referencing findings]
- **Alternatives considered:** [what else was on the table]
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
| ------------ | ------- | --- |
| One-search research | Single query, single page, declaration of "done" | Run the five-phase loop. The first search rarely answers the question |
| LLM-as-source | Citing the model's training data as evidence | Tier 4 is orientation only. Verify against tier 1–3 |
| No gap check | Synthesising and moving on without evaluating completeness | Run the gap-check questions. They take 2 minutes and prevent rework |
| Source dump | Listing URLs without evaluation or synthesis | Each source needs a confidence annotation and a one-sentence "what we learned" |
| Infinite refinement | "One more search" forever | The success criteria from Phase 1 are the stop condition. If they're met, publish |

## Tool Mapping

This skill maps to the tool set available in Copilot Chat:

| Research phase | Copilot tool |
| -------------- | ------------ |
| Search | `fetch_webpage` (primary), `github_repo`, `github_text_search` |
| Read source code | `read_file`, `grep_search`, `semantic_search` |
| Evaluate | Human judgment (the researcher reads and annotates) |
| Synthesise | `create_file` (write the research note) |
| Gap check | `read_file` (re-read the synthesis against criteria) |

## References

- Anthropic (2024). "Building Effective Agents" — the evaluator-optimizer
  and orchestrator-workers patterns that inform the research loop.
  https://www.anthropic.com/engineering/building-effective-agents
- Yao et al. (2023). "ReAct: Synergizing Reasoning and Acting in Language
  Models" — the Thought→Action→Observation loop. ICLR 2023.
  https://arxiv.org/abs/2210.03629
- Weng, Lilian (2023). "LLM-Powered Autonomous Agents" — the planning,
  memory, and tool-use decomposition of agent systems.
  https://lilianweng.github.io/posts/2023-06-23-agent/
