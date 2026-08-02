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
