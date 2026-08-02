- **Date**: 2026-08-02
- **Agent**: orchestrator (manual — direct collaboration)
- **Task**: Design and implement research pipeline: technical-researcher skill + agent, research-reviewer adversarial agent, codebase-analyst skill + agent, context isolation between internal/external research
- **Surprise**: The initial single-agent design had two structural gaps that emerged during review:
  1. Self-evaluation (Phase 5 gap-check) is insufficient for adversarial scrutiny — the same model checking its own work cannot reliably detect confirmation bias, source misreading, or unstated assumptions. The project already had `advocatus-diaboli` for this pattern; the research pipeline needed its equivalent.
  2. A single agent with both web and codebase tools would context-pollute — chasing external tangents instead of finishing structural analysis, and confusing "what the docs say" with "what the code does." Two fundamentally different activities were sharing one agent.
  3. The split into internal (codebase-analyst) and external (technical-researcher) with a two-mode adversarial reviewer (research-reviewer) mirrors the main pipeline's spec-writer→advocatus-diaboli→choice-cartographer pattern.

- **Proposal**: Add to AGENTS.md ARCH_DECISIONS: "Research is split into internal (codebase-analyst, workspace tools only) and external (technical-researcher, web tools only) with adversarial review (research-reviewer, two modes). Agents are context-isolated — fresh dispatch per agent, no shared state. The handoff mechanism: analyst flags External Research Needed items, orchestrator dispatches researcher against the specific question."
- **Improvement**: The split architecture adds dispatch latency for questions spanning both domains (two dispatches instead of one). Most research questions are either internal or external, not both, so this is acceptable. The three-agent maintenance burden is mitigated by shared skill infrastructure.

- **Signal**: design
- **Constraint**: Research pipeline must include adversarial review — no research note is acted on without a research-reviewer pass. Same principle as the main pipeline's diaboli gate.
- **Session metadata**:
  - Duration: 90 min
  - Model tiers used: flagship (100%)
  - Pipeline stages completed: N/A (design session)
  - Agent delegation: none
