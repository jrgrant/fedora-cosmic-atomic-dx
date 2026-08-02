- **Date**: 2026-07-14
- **Agent**: orchestrator (manual — no pipeline, direct collaboration)
- **Task**: Post-build validation: fix circular bootstrap reference, correct ujust justfile path, test on live system
- **Surprise**: Three interconnected failures discovered only after a successful 26-minute build:
  1. `ujust bootstrap` returned "recipe not found" — our custom justfile was at `justfiles/` but `ujust` looks in `just/`. The upstream `ujust` script runs `just --justfile /usr/share/ublue-os/justfile` which imports from `/usr/share/ublue-os/just/`. We had the wrong directory name.
  2. Our `update` recipe would silently shadow the upstream system `update` (which handles `uupd` service orchestration with verbosity levels). `allow-duplicate-recipes` is set to true, so no error — just silent breakage.
  3. The `[bootstrap]`, `[info]`, `[update]`, `[rollback]` annotations before recipe names aren't valid just syntax — they're not recognised attributes and would either be ignored or error.
  4. The Justfile `bootstrap` target → `scripts/bootstrap.sh` → `ujust bootstrap` creates a circular reference when `ujust` resolves to `just` and a local `Justfile` with a `bootstrap` target is in scope.
  5. Live testing on an atomic system can't `cp` into `/usr` — immutable. Direct `just --justfile` is the iteration path.

- **Proposal**: Add to AGENTS.md GOTCHAS:
  - "ujust justfiles belong in `/usr/share/ublue-os/just/`, not `justfiles/`. The entry point `/usr/share/ublue-os/justfile` imports from `just/`."
  - "Custom ujust recipe names must not collide with upstream recipes. Check `/usr/share/ublue-os/just/*.just` before naming. Prefer namespaced names (e.g. `rebase-helper` not `update`)."
  - "Justfile targets that delegate to ujust recipes must use a different name to avoid circular resolution when `ujust` falls through to `just`."
  - "Atomic images: `/usr` is immutable at runtime. Iterate on justfiles with `just --justfile <path>`, not by copying into `/usr`."

- **Improvement**: The build succeeded but three categories of defect (wrong path, name collision, invalid syntax) passed through undetected. A pre-build validation agent that checks:
  - All `system_files/` paths resolve to their expected runtime locations
  - Custom justfile recipe names don't collide with upstream
  - `just --justfile <file> --check` passes on all justfiles
  would catch these in seconds rather than after a 26-minute build + reboot. Consider adding `just --check` to the existing `shellcheck`/`yamllint` test suite.

- **Signal**: failure
- **Constraint**: ujust recipe names must not shadow upstream recipes — add a CI check that diffs custom recipe names against upstream `/usr/share/ublue-os/just/*.just`
- **Session metadata**:
  - Duration: 45 min
  - Model tiers used: standard (100%)
  - Pipeline stages completed: N/A (manual session)
  - Agent delegation: none
