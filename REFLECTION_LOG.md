# Reflection Log

<!-- GENERATED FILE — do not edit by hand.

     This file is a deterministic aggregate of the per-entry fragments in
     reflections/active/ (one file per reflection, so concurrent reflections
     never collide on a shared file and can never be silently dropped at
     merge time). Add a reflection with /reflect, which writes a fragment and
     regenerates this file; never append here directly. Regenerate with:
     scripts/regenerate-reflection-log.sh

     Each entry below mirrors one fragment. Fragment body format (no leading
     `---` — the separator belongs only to this aggregate):

     ---

     - **Date**: YYYY-MM-DD
     - **Agent**: integration-agent
     - **Task**: [one-sentence summary]
     - **Surprise**: [anything unexpected during the pipeline run]
     - **Proposal**: [what to add to AGENTS.md, or "none"]
     - **Improvement**: [what would make the process better]
     - **Signal**: [context | instruction | workflow | failure | none]
     - **Constraint**: [proposed constraint, or "none"]
     - **Session metadata**:
       - Duration: [e.g. "45 min" or "unknown"]
       - Model tiers used: [e.g. "capable (30%), standard (70%)" or "unknown"]
       - Pipeline stages completed: [e.g. "5/5" or "spec-writer, tdd-agent"]
       - Agent delegation: [full pipeline | partial | manual | unknown]

---

- **Date**: 2026-06-20
- **Agent**: orchestrator (DeepSeek V4 Pro)
- **Task**: Phase 2-4: Containerfile MVP, CI pipeline, bootstrap script — full pipeline from spec through integration
- **Surprise**: FCA base image differs from Silverblue in small but critical ways — missing `/usr/share/ublue-os/`, COPR chroot resolution breaks if `ID` is changed in os-release, service units from brew layer land in system paths not user paths. Five build OODA iterations before first green build. Clean podman storage was needed for final build.
- **Proposal**: Add to AGENTS.md GOTCHAS: "FCA base is not Silverblue — assume directories and service units present in UBlue/Bluefin may be absent. Guard all systemctl enables with || true, mkdir -p before writing to /usr/share/ublue-os/, and never change ID in os-release."
- **Improvement**: The OODA loop between build-fail-fix-push-rebuild was slow due to terminal tool limitations. A local build-test-iterate cycle (podman build, check errors, fix source, podman build) would be faster than pushing every fix through git. Consider adding a `scripts/build-test.sh` that wraps podman build with error capture and drops into a fix loop.
- **Signal**: workflow
- **Constraint**: Containerfile build must pass locally before CI is re-enabled — add "Local build gate" constraint
- **Session metadata**:
  - Duration: 3.5 hours
  - Model tiers used: flagship (100%) — orchestrator ran as single model
  - Pipeline stages completed: 6/6 (carpaccio, spec-writer, advocatus-diaboli, choice-cartographer, tdd-agent, implementer, code-reviewer, integration-agent) × 3 phases
  - Agent delegation: full pipeline

---

- **Date**: 2026-07-14
- **Agent**: orchestrator (manual — no pipeline, direct collaboration)
- **Task**: Post-build validation: fix circular bootstrap reference, correct ujust justfile path, test on live system
- **Surprise**: Three interconnected failures discovered only after a successful 26-minute build:
  1. `ujust bootstrap` returned "recipe not found" — our custom justfile was at `justfiles/` but `ujust` looks in `just/`. The upstream `ujust` script runs `just --justfile /usr/share/ublue-os/justfile` which imports from `/usr/share/ublue-os/just/`. We had the wrong directory name.
  2. Our `update` recipe would silently shadow the upstream system `update` (which handles `uupd` service orchestration with verbosity levels). `allow-duplicate-recipes` is set to true, so no error — just silent breakage.
  3. The `[bootstrap]`, `[info]`, `[update]`, `[rollback]` annotations before recipe names aren't valid just syntax — they're not recognised attributes and would either be ignored or error.
  4. The Justfile `bootstrap` target → `scripts/bootstrap.sh` → `ujust bootstrap` creates a circular reference when `ujust` resolves to `just` and a local `Justfile` with a `bootstrap` target is in scope.
  5. Live testing on an atomic system can't `cp` into `/usr` — immutable. Direct `just --justfile` is the iteration path.
- **Proposal**: Add to AGENTS.md GOTCHAS: ujust justfile path, recipe name collisions, circular delegation trap, atomic filesystem iteration, invalid just syntax.
- **Improvement**: The build succeeded but three categories of defect (wrong path, name collision, invalid syntax) passed through undetected. A pre-build validation agent that checks: all `system_files/` paths resolve to their expected runtime locations, custom justfile recipe names don't collide with upstream, and `just --justfile <file> --check` passes on all justfiles — would catch these in seconds rather than after a 26-minute build + reboot. Consider adding `just --check` to the existing `shellcheck`/`yamllint` test suite.
- **Signal**: failure
- **Constraint**: ujust recipe names must not shadow upstream recipes — add a CI check that diffs custom recipe names against upstream `/usr/share/ublue-os/just/*.just`
- **Session metadata**:
  - Duration: 45 min
  - Model tiers used: standard (100%)
  - Pipeline stages completed: N/A (manual session)
  - Agent delegation: none

---

- **Date**: 2026-07-16 — 2026-07-17
- **Agent**: Manual collaboration (no pipeline)
- **Task**: Post-build validation: fix credential persistence, correct ujust path, switch to Flatpak apps
- **Surprise**: 
  1. **Chrome 150 cannot use gnome-keyring on COSMIC** — the `--password-store=gnome-libsecret` flag is accepted but `freedesktop_secret_key_provider.cc` silently fails. The XDG Desktop Portal Secret backend (`org.freedesktop.impl.portal.Secret`) has no working implementation — `gnome-keyring-daemon --start` doesn't implement the portal interface. Chrome falls back to basic mode which requires `--no-first-run` and a clean profile.
  2. **COSMIC 1.3.0 upgrade (via adil192 COPR) succeeded** — but didn't ship `oo7-daemon` or `oo7-portal`. The COSMIC portals.conf already prefers `oo7-portal;gnome-keyring` but neither backend works on F44.
  3. **The `~/.opt` hack install approach was a dead end** — rpm2cpio extraction, desktop file wrangling, icon extraction, flag juggling. Flatpak is simpler and the portal fix (`UseIn=COSMIC`) enables portal-based secrets when `oo7` eventually lands.
  4. **`First Run` sentinel caused Chrome session loss** — Chrome's profile from m2os was corrupted; a fresh profile with `--no-first-run` resolves it.
  5. **rpm-ostree won't rebase by tag** — reusing the same `:44` tag produces identical manifests; must rebase by explicit digest.
- **Proposal**: Multiple gotchas to AGENTS.md — see below.
- **Improvement**: The 26-minute build loop made iteration slow. A pre-build validation agent that checks justfile syntax, portal configs, and recipe name collisions would catch these in seconds.
- **Signal**: workflow
- **Constraint**: Bootstrap recipe must use Flatpak for user apps — no more `~/.opt` hack installs.
- **Session metadata**:
  - Duration: ~8 hours across 2 days
  - Model tiers used: standard (100%)
  - Pipeline stages completed: N/A (manual)
  - Agent delegation: none
