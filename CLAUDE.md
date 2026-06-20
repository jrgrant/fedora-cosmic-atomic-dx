# Project Conventions

## Literate Programming

All code written in this project follows Don Knuth's literate programming principles.
The full skill is at `.claude/skills/literate-programming/SKILL.md`.

When creating a new source file or significantly rewriting an existing one, read
`.claude/skills/literate-programming/SKILL.md` and apply it before writing any code.

The five rules in brief:

1. Every file opens with a narrative preamble — why it exists, key design decisions,
   what it deliberately does NOT do
2. Documentation explains reasoning, not signatures — WHY the design is this way,
   not what the function returns
3. Order of presentation follows logical understanding — orchestration before detail,
   concept before mechanism
4. Each file has one clearly stated concern — named in the first sentence of the preamble
5. Inline comments explain WHY, not WHAT — the code already shows what happens

## CUPID Code Review

When reviewing or refactoring code, apply the CUPID lens documented at
`.claude/skills/cupid-code-review/SKILL.md`.

The five properties in brief:

1. **Composable** — can it be used independently without hidden dependencies?
2. **Unix philosophy** — does it do one thing completely and well?
3. **Predictable** — does it behave as its name suggests, with no hidden side effects?
4. **Idiomatic** — does it follow the grain of the language and project conventions?
5. **Domain-based** — do its names come from the problem domain, not the technical implementation?

## Workflow

### Spec-First Change Discipline

Any change to application behaviour must flow through the spec before touching
implementation code:

1. Update the spec — add or revise user stories, acceptance scenarios, and FRs
2. Update the implementation plan — reflect new or changed FRs
3. Write failing tests from the spec — confirm red before writing implementation
4. Update the implementation — until failing tests turn green
5. Refactor — clean up while keeping all tests green

### Test-Driven Development

Follow red-green-refactor strictly:

1. RED — write a failing test that describes the desired behaviour
2. GREEN — write the minimal production code needed to make the test pass
3. REFACTOR — clean up while keeping all tests green

No production code without a failing test first.

### Branch Discipline

Never commit directly to `main`. At the start of any task:

1. Create a GitHub issue describing the task
2. Create a branch: `git checkout -b <short-descriptive-name>`
   (lowercase, hyphen-separated, e.g. `add-search`, `fix-renderer-wrapping`)

### Commit Messages

Write concise commit messages that describe what changed and why. No postamble,
no attribution lines. The message ends when the description ends.

### CHANGELOG

Before every PR, update CHANGELOG.md:

- Add a dated section at the top if today's date is not already present

## Build and Test

This is a documentation, configuration, and scripting project. There is no
compiled language or build system.

- **Shell scripts**: validate with `shellcheck`
- **YAML**: validate with `yamllint` or `python3 -c "import yaml; ..."`
- **Markdown**: validate with `markdownlint-cli2`
- **JSON**: validate with `python3 -c "import json; ..."`

## Conventions (extracted 2026-06-20)

- **Containerisation heuristic for script/module design**: apply the same
  tests that make a good container — single concern, minimal surface area,
  reproducible from source, well-defined entrypoint, no sprawl. If a module
  would make a bad container, it's likely over-engineered.

## Learnings

<!-- Patterns, gotchas, and decisions accumulate here as the project progresses.
     See AGENTS.md for the structured compound-learning registry. -->
