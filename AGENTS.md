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

- **Context-isolated agent dispatch**: When two agents handle different domains
  (e.g. codebase vs web), dispatch them independently with fresh context rather
  than chaining. The handoff is an artifact (a research note), not shared state.
  Each agent's tool set is scoped to its domain — no web tools for codebase
  agents, no codebase-exploration tools for web agents. This prevents context
  pollution and makes findings independently verifiable.

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

- **ujust justfile path**: `ujust` runs `just --justfile /usr/share/ublue-os/justfile`,
  which imports from `/usr/share/ublue-os/just/`. Custom recipes go in
  `/usr/share/ublue-os/just/60-custom.just` (imported with `import?` — optional).
  The directory is `just/`, not `justfiles/`.

- **ujust recipe name collisions**: Upstream recipes are in `/usr/share/ublue-os/just/`.
  `allow-duplicate-recipes` is set — last import wins silently. Check for collisions
  before naming custom recipes. Prefer namespaced names (e.g. `rebase-helper`, not
  `update`).

- **Circular delegation trap**: A Justfile target that delegates to a ujust recipe
  must use a different name. `just bootstrap` → `ujust bootstrap` loops if `ujust`
  resolves through `just` and finds the local `Justfile`. Name the Justfile target
  differently (e.g. `setup`).

- **Atomic filesystem at runtime**: `/usr` is read-only on booted atomic systems.
  Iterate on justfiles with `just --justfile <path>`, not by copying into `/usr`.
  Changes require a rebuild to persist across reboots.

- **rpm-ostree rebase with fixed tags**: Rebuilding with the same `:tag` produces a
  new manifest digest, but rpm-ostree resolves the tag to the booted manifest and
  refuses rebase ("Old and new refs are equal"). Always rebase by explicit digest:
  `rpm-ostree rebase ...:tag@sha256:$(sudo podman image inspect ... --format '{{.Digest}}')`

- **[just] annotation syntax**: `[name]` lines before recipe definitions are not
  valid just syntax unless `name` is a recognised attribute (`private`, `no-cd`,
  etc.). Use `# comments` for section headers.

- **COSMIC keyring integration is broken upstream**: The XDG Desktop Portal secrets
  backend (`gnome-keyring.portal`) has `UseIn=gnome` — excludes COSMIC. Chrome/Electron
  apps use the portal API, not direct libsecret, so they silently fall back to basic
  (non-persistent) storage. Fix: add `;COSMIC` to `UseIn=` in the portal file and
  `OnlyShowIn=` in autostart files. Chrome 150+ needs `--password-store=gnome-libsecret`
  (not `gnome`).

- **VS Code install strategy**: Custom `~/.opt` tarball install adds complexity
  (manual desktop files, icon extraction, `--no-sandbox` flags) without solving
  credential persistence. Prefer `brew install --cask visual-studio-code-linux`.
  See `docs/research/vscode-install-strategy.md`.

- **Agent files ≠ registered agents**: Agent `.agent.md` files in
  `ai-literacy-superpowers/agents/` are documentation until registered
  with the VS Code agent API. The `runSubagent` tool cannot dispatch them.
  Until registration is complete, the orchestrator runs analysis inline.
  See `reflections/active/2026-08-02-agent-not-registered.md`.

- **Self-review of research is confirmation bias**: An agent reviewing its
  own research note is re-reading files it already read with the same
  conclusions already formed — it will not find evidence mismatches, missed
  counterexamples, or pattern overfitting. Adversarial review REQUIRES
  independent context (fresh dispatch, no prior knowledge of the analysis).
  If the research-reviewer agent is not registered, dispatch Explore or
  another subagent with the review protocol and the note file path. Never
  run the review inline. A self-review that finds zero objections is a red
  flag, not a clean bill of health.
  See `reflections/active/2026-08-02-adversarial-review-circle-jerk.md`.

## ARCH_DECISIONS

- **Decision**: Use git submodules for reference repos (m2os, ublue, bluefin, fca) rather than in-tree copies.
  **Reason**: These are read-only references — we read and diff them but never modify. Submodules pin a specific commit, making diffs deterministic.
  **Alternatives considered**: shallow clones (rejected — no commit pinning), vendored copies (rejected — bloats repo, drifts).

- **Decision**: Project root holds harness config + output artifacts; submodules hold references.
  **Reason**: Clean separation between our work product and upstream sources. The harness (CLAUDE.md, HARNESS.md, agents, CI) is first-class project content.

- **Decision**: Research is split into internal (codebase-analyst, workspace tools only) and external (technical-researcher, web tools only) with adversarial review (research-reviewer, two modes: external/codebase). Agents are context-isolated — fresh dispatch per agent, no shared state. The handoff mechanism: analyst flags External Research Needed items, orchestrator dispatches researcher against the specific question.
  **Reason**: A single agent with both web and codebase tools context-pollutes — chasing external tangents instead of finishing structural analysis, and confusing "what the docs say" with "what the code does." Self-review (gap-check) is necessary but insufficient; adversarial review by an independent agent with fresh context catches confirmation bias, source misreading, and unstated assumptions. This mirrors the main pipeline's spec-writer→advocatus-diaboli pattern.
  **Alternatives considered**: single agent with modes (rejected — mode-switching within one context window doesn't solve context pollution), no adversarial review (rejected — contradicts established pipeline pattern).
  **See:** `docs/superpowers/adr/2026-08-02-split-research-architecture.md`

## TEST_STRATEGY

- Shell scripts: validate with `shellcheck` (all scripts under `scripts/`)
- YAML files: structural validation with Python `yaml.safe_load`
- Markdown: `markdownlint-cli2` for consistency
- JSON: Python `json.load` structural check
- CI runs all of the above on every PR

## DESIGN_DECISIONS

<!-- Key design decisions and their rationale. -->
