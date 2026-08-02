---
date: 2026-08-02
spec: docs/superpowers/specs/2026-08-02-upstream-dependency-catalog-recommendations.md
slices: [S6]
---

# Upstream Dependency Catalog Recommendations — Implementation Plan

## S6: Consolidate justfile divergence and choose browser install mechanism

### Module Structure

| File | Action | Rationale |
|------|--------|-----------|
| `system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just` | **DELETE** | Dead code — not in ujust's import path, uses `~/.opt` rpm2cpio pattern that breaks the atomic filesystem idiom. The active `60-custom.just` already covers all four recipes with namespaced names and Flatpak installs. |
| `system_files/shared/usr/share/ublue-os/just/60-custom.just` | **VERIFY (no change expected)** | Already uses Flatpak for Chrome, Brave, and VS Code; already has namespaced recipe names; already has no `~/.opt` references. Confirmed clean by grep. |
| `build_files/base/20-cosmic-keyring-fix.sh` | **VERIFY (no change expected)** | Already patches `gnome-keyring.portal` for COSMIC `UseIn=` and autostart files for `OnlyShowIn=`. Confirmed by inspection — both fixes are present. |

### Algorithm Notes

**Decision: Flatpak over ~/.opt rpm2cpio.** The `~/.opt` extraction pattern creates
unmanaged, unversioned binaries in the user's home directory with no update
mechanism, no integrity verification, and no rollback — it violates the core
premise of an atomic desktop where `/usr` is read-only and system state is
managed by rpm-ostree. Flatpak provides sandboxing, updates via `flatpak update`,
and rollback support. The credential persistence issue that motivated the
`~/.opt` pivot is addressed by the COSMIC keyring portal fix
(`20-cosmic-keyring-fix.sh`), which patches the XDG Desktop Portal to accept
COSMIC as a valid desktop for the secrets backend.

**Why only delete, not modify:** The active justfile (`60-custom.just`) already
uses the correct Flatpak approach. No code changes are needed — S6 is a cleanup
(deletion of dead code) and a verification that the active path is correct.

**COSMIC keyring service at bootstrap:** The `fca-bootstrap` recipe runs
`systemctl --user enable --now cosmic-keyring-env.service 2>/dev/null || true`.
This is a runtime complement to the build-time portal patch. The `|| true` guard
follows the AGENTS.md gotcha: FCA base image may not include this service, and
we must not fail bootstrap if it's absent. The build-time fix in
`20-cosmic-keyring-fix.sh` is the critical path for credential persistence; the
runtime service activation is a belt-and-suspenders addition.

### FR Mapping

| FR | Test Case | Verification Method |
|----|-----------|---------------------|
| FR-S6-1 | TC1 | File existence check (file must NOT exist) |
| FR-S6-2 | TC2 | Grep `60-custom.just` for `flatpak install.*com.google.Chrome` |
| FR-S6-3 | TC3 | Grep `60-custom.just` for `flatpak install.*com.brave.Browser` |
| FR-S6-4 | TC4 | Grep `60-custom.just` for `flatpak install.*com.visualstudio.code` |
| FR-S6-5 | TC5 | Grep `60-custom.just` for skip-guard pattern (`if ! flatpak list.*grep -q`) |
| FR-S6-6 | TC6 | Grep `60-custom.just` for `~/.opt`, `rpm2cpio`, `cpio -idmv` — must return zero matches |
| FR-S6-7 | TC7 | Grep `20-cosmic-keyring-fix.sh` for `UseIn=gnome;COSMIC` in portal patch |
| FR-S6-8 | TC8 | Grep `20-cosmic-keyring-fix.sh` for `OnlyShowIn=.*COSMIC` in autostart patch |
| FR-S6-9 | TC9 | Grep `60-custom.just` for `flatpak run.*--version.*echo.*not installed` |
| FR-S6-10 | TC10 | Grep `60-custom.just` for `flatpak update -y` in `rebase-helper` recipe |

### Test Case List

1. **TC1 (FR-S6-1):** `test ! -f system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just` — file must not exist
2. **TC2 (FR-S6-2):** `grep -q 'flatpak install.*flathub com.google.Chrome' system_files/shared/usr/share/ublue-os/just/60-custom.just` — Chrome Flatpak install command present
3. **TC3 (FR-S6-3):** `grep -q 'flatpak install.*flathub com.brave.Browser' system_files/shared/usr/share/ublue-os/just/60-custom.just` — Brave Flatpak install command present
4. **TC4 (FR-S6-4):** `grep -q 'flatpak install.*flathub com.visualstudio.code' system_files/shared/usr/share/ublue-os/just/60-custom.just` — VS Code Flatpak install command present
5. **TC5 (FR-S6-5):** `grep -q 'if ! flatpak list.*grep -q' system_files/shared/usr/share/ublue-os/just/60-custom.just` — install-guard pattern present for all three apps
6. **TC6 (FR-S6-6):** `! grep -qE '~/\.opt|rpm2cpio|cpio -idmv' system_files/shared/usr/share/ublue-os/just/60-custom.just` — no ~/.opt or rpm2cpio references
7. **TC7 (FR-S6-7):** `grep -q 'UseIn=gnome;COSMIC' build_files/base/20-cosmic-keyring-fix.sh` — portal UseIn patch present
8. **TC8 (FR-S6-8):** `grep -q 'OnlyShowIn=.*COSMIC' build_files/base/20-cosmic-keyring-fix.sh` — autostart OnlyShowIn patch present
9. **TC9 (FR-S6-9):** `grep -q 'flatpak run.*--version' system_files/shared/usr/share/ublue-os/just/60-custom.just` — Flatpak-based version queries in fca-info
10. **TC10 (FR-S6-10):** `grep -q 'flatpak update -y' system_files/shared/usr/share/ublue-os/just/60-custom.just` — Flatpak update in rebase-helper

All tests are shell-level verification (grep/file-existence checks). They can be
run as a shell script or as individual assertions. The tests verify structural
properties of the codebase — that the right patterns exist in the right files
and the wrong patterns don't. They do not execute the justfile recipes.
