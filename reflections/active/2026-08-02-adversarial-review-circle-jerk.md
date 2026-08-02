---
date: 2026-08-02
agent: orchestrator (DeepSeek V4 Pro)
task: "Research pipeline: determine which dependencies can be externalized to submodules"
surprise: "Self-review of a research note is structurally broken — same agent, same context window, same files already read. The first 'review' found zero objections. A genuinely independent review (Explore subagent, fresh context) found 17 — including one severe misreading where I fabricated 'improvements' that exist identically in both files."
proposal: "Add to AGENTS.md GOTCHAS: 'Self-review of research notes is confirmation bias. The research-reviewer agent must have independent context (fresh dispatch, no prior knowledge of the analysis). If the agent is not registered, dispatch Explore or another subagent with the review protocol and the note file path — do not run the review inline.'"
improvement: "Register the research-reviewer agent with the VS Code agent API. Until then, the orchestrator must always dispatch an independent subagent for adversarial review — never do it inline. The cost is one extra dispatch; the alternative is fabricated findings surviving into decisions."
signal: failure
constraint: "Research notes require independent adversarial review with fresh context before informing any decision (implementation, architecture, or dependency changes). Self-review (same agent, same context) does not satisfy this constraint."
session_metadata:
  duration: "45 min"
  model_tiers_used: "flagship (100%)"
  pipeline_stages_completed: "N/A (research task — analysis + adversarial review)"
  agent_delegation: "partial — Explore subagent for review"
