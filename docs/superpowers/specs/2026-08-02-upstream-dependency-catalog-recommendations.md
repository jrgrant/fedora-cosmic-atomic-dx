---
date: 2026-08-02
status: drafted
carpaccio_slug: upstream-dependency-catalog-recommendations
carpaccio_total_slices: 8
carpaccio_progressed_slice: S6
source_analysis: docs/research/2026-08-02-upstream-dependency-catalog.md
source_review: docs/research/2026-08-02-upstream-dependency-catalog-review.md
parent_slicing_record: docs/superpowers/slices/upstream-dependency-catalog-recommendations.md
issue: 54
---

# Upstream Dependency Catalog Recommendations — Spec

## 1. Problem

The upstream dependency catalog research
(`docs/research/2026-08-02-upstream-dependency-catalog.md`) identified 11
actionable recommendations (R1–R11) across the project's OCI images, COPR
repositories, runtime URL fetches, CI dependencies, and user-facing bootstrap
scripts. All recommendations were accepted after adversarial review. This spec
describes the expected behaviour changes from a user's perspective before
implementation begins.

## 2. Scope

Eight slices (S1–S8) as defined in the parent slicing record
(`docs/superpowers/slices/upstream-dependency-catalog-recommendations.md`).
Each slice is independently specified below. The current progressed slice is S6.

---

## S6: Consolidate justfile divergence and choose browser install mechanism

### S6.1 Problem

Two justfiles serve the same purpose but have diverged implementations:

- `60-custom.just` — the **active** file imported by ujust. Uses namespaced
  recipe names (`fca-bootstrap`, `fca-info`, `rebase-helper`, `fca-rollback`)
  and installs Chrome and Brave via Flatpak, and VS Code via brew cask. Respects the atomic
  desktop idiom.
- `fedora-cosmic-atomic-dx.just` — a **dead** file in `justfiles/` (not in
  ujust's import path). Uses bare recipe names (`bootstrap`, `info`, `update`,
  `rollback`) and installs Chrome, Brave, and VS Code via `rpm2cpio` extraction
  into `~/.opt`, creating unmanaged, unversioned binaries in the user's home
  directory.

The `~/.opt` rpm2cpio pattern (F8 in the research) breaks the immutable
filesystem contract: there is no update mechanism, no integrity verification,
and no rollback. The pivot to `~/.opt` was motivated by credential persistence
issues with Flatpak-installed browsers, but the COSMIC keyring portal fix
(`build_files/base/20-cosmic-keyring-fix.sh`) should resolve those issues.

The decision is to keep the Flatpak direction (60-custom.just), delete the dead
justfiles/ variant, and verify Flatpak credential persistence works with the
COSMIC keyring fix.

### S6.2 User Story

**As a** user running `ujust fca-bootstrap` on a fresh fedora-cosmic-atomic
system,
**I want** Chrome and Brave installed via Flatpak, and VS Code installed via brew cask,
**So that** my applications are managed by the immutable system's Flatpak layer
with proper sandboxing, update mechanisms, and rollback support, rather than
unmanaged binaries in my home directory that bypass the atomic filesystem
contract.

### S6.3 Acceptance Scenarios

**Scenario 1: Dead justfile is removed**

- **Given** the repository at its current state with two diverged justfiles
- **When** S6 is implemented
- **Then** `system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just`
  no longer exists
- **And** a recursive grep for bare recipe names `bootstrap`, `info`, `update`,
  `rollback` in the `justfiles/` directory returns no matches (the directory
  itself may remain empty or be removed)

**Scenario 2: Active justfile installs apps via Flatpak**

- **Given** `60-custom.just` as the sole justfile for custom recipes
- **When** a user runs `ujust fca-bootstrap`
- **Then** Chrome is installed via `flatpak install -y flathub com.google.Chrome`
- **And** Brave is installed via `flatpak install -y flathub com.brave.Browser`
- **And** VS Code is installed via `brew install --cask visual-studio-code-linux`
- **And** each install is guarded by a pre-check that skips if already installed

**Scenario 3: No ~/.opt or rpm2cpio references remain**

- **Given** `60-custom.just` as the sole justfile for custom recipes
- **When** S6 is implemented
- **Then** `grep -r '~/.opt\|rpm2cpio\|cpio -idmv'` in the active justfile
  (`system_files/shared/usr/share/ublue-os/just/60-custom.just`) returns
  zero matches

**Scenario 4: COSMIC keyring portal fix is in place for credential persistence**

- **Given** the COSMIC keyring fix at `build_files/base/20-cosmic-keyring-fix.sh`
- **When** the image is built and booted, and a user runs `ujust fca-bootstrap`
- **Then** the `gnome-keyring.portal` file has `UseIn=gnome;COSMIC` (applied at
  build time)
- **And** the `gnome-keyring-{secrets,pkcs11,ssh}.desktop` autostart files have
  `OnlyShowIn=GNOME;Unity;MATE;COSMIC` (applied at build time)
- **And** Chrome launched via Flatpak can persistently save credentials across
  reboots when launched with `--password-store=gnome-libsecret`

**Scenario 5: Info recipe uses Flatpak paths for version queries**

- **Given** `60-custom.just` as the active justfile
- **When** a user runs `ujust fca-info`
- **Then** VS Code version is queried via `code --version`
- **And** Chrome version is queried via `flatpak run com.google.Chrome --version`
- **And** Brave version is queried via `flatpak run com.brave.Browser --version`
- **And** each query gracefully falls back to `not installed` if the app is absent

**Scenario 6: Rebase-helper updates Flatpak apps**

- **Given** `60-custom.just` as the active justfile
- **When** a user runs `ujust rebase-helper`
- **Then** `flatpak update -y` is executed to update all Flatpak-installed
  applications

### S6.4 Functional Requirements

| ID | Requirement | Source |
|----|------------|--------|
| FR-S6-1 | `system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just` must not exist | Scenario 1 |
| FR-S6-2 | `60-custom.just` must install Chrome via `flatpak install -y flathub com.google.Chrome` | Scenario 2 |
| FR-S6-3 | `60-custom.just` must install Brave via `flatpak install -y flathub com.brave.Browser` | Scenario 2 |
| FR-S6-4 | `60-custom.just` must install VS Code via `brew install --cask visual-studio-code-linux` (per `docs/research/vscode-install-strategy.md`, 2026-07-16) | Scenario 2 |
| FR-S6-5 | Each Flatpak install command must be guarded by a pre-check that skips if the app is already installed | Scenario 2 |
| FR-S6-6 | `60-custom.just` must contain no references to `~/.opt`, `rpm2cpio`, or `cpio -idmv` | Scenario 3 |
| FR-S6-7 | `build_files/base/20-cosmic-keyring-fix.sh` must patch `gnome-keyring.portal` to add `COSMIC` to `UseIn=` | Scenario 4 |
| FR-S6-8 | `build_files/base/20-cosmic-keyring-fix.sh` must patch `gnome-keyring-{secrets,pkcs11,ssh}.desktop` to add `COSMIC` to `OnlyShowIn=` | Scenario 4 |
| FR-S6-9 | `60-custom.just` `fca-info` recipe must query app versions: Chrome and Brave via `flatpak run <app-id> --version` with `\|\| echo 'not installed'` fallback; VS Code via `code --version` with fallback | Scenario 5 |
| FR-S6-10 | `60-custom.just` `rebase-helper` recipe must run `flatpak update -y` | Scenario 6 |

### S6.5 Exclusions

- **Pinning bootstrap URLs** (R8 / S7): Adding version-pinned alternatives as
  comments alongside mutable defaults is deferred to S7, which depends on S6's
  direction being settled.
- **Standardizing Flathub URL** (R9 / S7): The two-form Flathub URL
  inconsistency (`flathub.org/repo/` in cleanup scripts vs `dl.flathub.org/repo/`
  in the justfile) is deferred to S7.
- **Adding new Flatpak apps beyond Chrome, Brave, and VS Code**: Out of scope.
  S6 only covers the three apps currently present in both justfiles.
- **Removing the `justfiles/` directory itself**: Only the one dead file is
  removed. If the directory becomes empty, removing it is a cleanup decision
  for the implementer, not a spec requirement.
- **Testing credential persistence end-to-end**: The COSMIC keyring fix is
  verified structurally (correct file patches exist at build time). End-to-end
  verification of credential persistence across reboots requires a booted
  system and is out of scope for this spec.

---

## S1–S5, S7–S8 (pending)

_These slices are not yet specified. They will be added as they are progressed._

