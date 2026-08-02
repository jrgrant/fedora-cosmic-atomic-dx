---
date: 2026-08-02
target: all upstream external dependencies
lens: dependency-graph, supply-chain, criticality
origin: codebase-analyst (Explore subagent)
status: complete
findings_count: 10
external_research_needed: false
reviewed: true
review_record: docs/research/2026-08-02-upstream-dependency-catalog-review.md
review_objections: 8 (all addressed in this revision)
supersedes: docs/research/2026-08-02-externalizable-dependencies.md
---

# Upstream External Dependencies — Complete Inventory

## Scope

**Target:** Every external dependency the project relies on — OCI container images,
RPM/COPR repositories, runtime URL fetches, git submodules, CI actions, and implicit
base-image tools. Categorize by criticality and recommend externalization where needed.

**Lens:** dependency-graph, supply-chain, criticality

**Success criteria:**
- [x] Every OCI image reference catalogued with pinning status
- [x] Every RPM/COPR repo catalogued with criticality assessment
- [x] Every runtime URL fetch catalogued
- [x] Implicit base-image dependencies identified
- [x] Criticality heatmap produced
- [x] Externalization recommendations for build-fatal and runtime-fatal dependencies

## Dependency Inventory

### OCI Container Images

| # | Dependency | Referenced at | Criticality | Pinning |
|---|---|---|---|---|
| 1 | `quay.io/fedora-ostree-desktops/cosmic-atomic:44` | `Containerfile:21,30` | Build-fatal | Mutable tag, CI-time digest pin via `BASE_IMAGE_DIGEST` |
| 2 | `ghcr.io/ublue-os/brew:latest` | `Containerfile:23,27` | Build-fatal | Mutable tag, CI-time digest pin via `BREW_IMAGE_SHA` |
| 3 | `ghcr.io/ublue-os/akmods:${FLAVOR}-${VER}` | `build_files/base/03-install-kernel-akmods.sh:21` | Build-fatal | **Unpinned mutable tag** |
| 4 | `ghcr.io/ublue-os/akmods-nvidia-open:${FLAVOR}-${VER}` | `build_files/base/03-install-kernel-akmods.sh:55` | Build-fatal | **Unpinned mutable tag** |

### RPM / COPR Repositories

| # | Dependency | Referenced at | Criticality | Pinning |
|---|---|---|---|---|
| 5 | Fedora 44 base repos | Implicit via `FROM cosmic-atomic:44` | Build-fatal | Fedora mirrors |
| 6 | `mirrors.rpmfusion.org` (free) | `03-install-kernel-akmods.sh:46` | Build-fatal | Mutable URL, ephemeral (installed→used→removed) |
| 7 | `mirrors.rpmfusion.org` (nonfree) | `03-install-kernel-akmods.sh:47` | Build-fatal | Mutable URL, ephemeral |
| 8 | `copr:ublue-os/packages` (uupd, ujust) | `04-packages.sh:102` | **Runtime-fatal** — auto-updates break if missing | Mutable COPR, no retry |
| 9 | `copr:adil192/cosmic-epoch` | `05-cosmic-upgrade.sh:13` | **Runtime-fatal** — COSMIC stuck at 1.1.0 | Hardcoded fedora-44 URL, single-maintainer COPR |
| 10 | `copr:che/nerd-fonts` | `04-packages.sh:99` | Cosmetic | Mutable COPR |
| 11 | `pkgs.tailscale.com` | `04-packages.sh:91` | Feature-degradation | Mutable URL, has retry loop (3x) |
| 12 | `download.docker.com` | `dx/00-dx.sh:81` | Feature-degradation | Mutable URL, no retry |
| 13 | `_copr_ublue-os-akmods` (conditional) | `03-install-kernel-akmods.sh:40-41`, `17-cleanup.sh:55-56` | **Build-fatal (conditional)** — COPR pre-installed in base image, enabled during kernel install, disabled at cleanup. If present and enabled, packages could be pulled from it during dnf operations | Pre-installed in FCA base image, conditionally enabled |
| 14 | `vscode.repo` | `validate-repos.sh:55` | **Unknown** — validated at build time but origin unclear. Either comes from FCA base image (should be catalogued) or is dead validation inherited from bluefin (should be removed) | Unknown — not created by our build scripts |
| 15-17 | Disabled repos (negativo17, cisco-openh264, coreos-pool) | `17-cleanup.sh:41,63-65` | Cosmetic | Pre-installed in base image, disabled at build |

### Runtime URL Fetches (Bootstrap / First Boot)

| # | Dependency | Referenced at | Criticality | Pinning |
|---|---|---|---|---|
| 16 | Homebrew installer (`raw.githubusercontent.com/.../HEAD/install.sh`) | `brew-setup:5` | Feature-degradation | Fetches and executes installer from HEAD via `/bin/bash -c "$(curl ...)"`, `\|\| true` guards failure |
| 17 | Flathub remote (`flathub.org/repo/flathub.flatpakrepo`) | `17-cleanup.sh:37`, `flatpak-nuke-fedora:5` | Cosmetic | Mutable URL |
| 18 | Google Chrome RPM (`dl.google.com/.../stable_current`) | `fedora-cosmic-atomic-dx.just:44` | Feature-degradation | Mutable URL, unversioned |
| 19 | Brave Browser RPM (`github.com/brave/.../latest/download`) | `fedora-cosmic-atomic-dx.just:55` | Feature-degradation | Mutable URL, redirects to latest |
| 20 | VS Code tarball (`code.visualstudio.com/sha/download?...`) | `fedora-cosmic-atomic-dx.just:66-67` | Feature-degradation | Mutable URL, redirects to latest |

### Git Submodules

| # | Dependency | Referenced at | Criticality | Pinning |
|---|---|---|---|---|
| 21 | `github.com/ublue-os/main.git` → `ublue/` | `.gitmodules` | Feature-degradation | Commit-pinned |
| 22 | `github.com/ublue-os/bluefin.git` → `bluefin/` | `.gitmodules` | Feature-degradation | Commit-pinned |
| 23 | `forge.fedoraproject.org/atomic-desktops/config.git` → `fca/` | `.gitmodules` | Feature-degradation | Commit-pinned |

### CI Dependencies

| # | Dependency | Referenced at | Criticality | Pinning |
|---|---|---|---|---|
| 24 | `actions/checkout@v4` | `build.yml:27` | Build-fatal | Mutable tag `@v4` |
| 25 | `ubuntu-latest` runner | `build.yml:18` | Build-fatal | Mutable tag |
| 26 | `podman` | `build.yml:38,46,52` | Build-fatal | Implicit (ubuntu-latest) |
| 27 | `bats` | `build.yml:32-33` | Feature-degradation | `apt-get install` |
| 28 | `cosign` | `build.yml:84-89` | Feature-degradation | **Implicit — not installed, relies on runner image** |

### Implicit Base-Image Tools

| # | Dependency | Used by | Criticality |
|---|---|---|---|
| 29 | `dnf5` | All package install scripts | Build-fatal |
| 30 | `skopeo` | `03-install-kernel-akmods.sh:21,55` | Build-fatal |
| 31 | `jq` | `03-install-kernel-akmods.sh:22,57` | Build-fatal |
| 32 | `flatpak` | `17-cleanup.sh:37` | Feature-degradation |
| 33 | `bootc` | `Containerfile:47` | Cosmetic (lint check) |

## Criticality Heatmap

### 🔴 Build-Fatal (cannot produce image)

Deps #1-7, #13 (conditional), #24-26, #29-31 — 15 dependencies. Base image, brew layer, akmods images, Fedora repos, RPMFusion, conditional COPR, CI runner, dnf5, skopeo, jq.

### 🟠 Runtime-Fatal (image builds but boots broken)

Deps #8 (uupd auto-updater), #9 (COSMIC desktop upgrade) — 2 dependencies. Both are COPR repos with no mirroring and no retry logic.

### 🟡 Feature-Degradation (specific features missing)

Deps #11-12, #16, #18-23, #27-28, #32 — 14 dependencies. Submodules, Tailscale, Docker, Homebrew, browsers, VS Code, bats, cosign, flatpak.

### 🟢 Cosmetic (no functional impact)

Deps #10, #15-17, #19 — 5 dependencies. Nerd Fonts, disabled repos, Flathub remotes.

## Findings

### F1: 🔴 akmods OCI images use `skopeo copy` instead of upstream's `FROM`-based pattern

**Severity:** high
**Evidence:** `build_files/base/03-install-kernel-akmods.sh:21,55` — `skopeo copy docker://ghcr.io/ublue-os/akmods:${AKMODS_FLAVOR}-${FEDORA_VER}` with no digest pinning. The upstream reference implementation in `ublue/Containerfile:8-19` already solves this with the same Null Object digest-pinning pattern used for base/brew images (`${AKMODS_DIGEST:+@${AKMODS_DIGEST}}`), and resolves digests from `ublue/Justfile:165-166` via `image-versions.yaml`. Our build uses a less reproducible `skopeo copy` approach that the upstream reference has already moved beyond.
**Why it matters:** Two issues: (1) non-reproducible builds (mutable tag with no digest), and (2) we're maintaining a different approach than the upstream reference architecture. The `ublue/` submodule already contains the solution — `FROM` + `--mount=type=bind` for RPM extraction is more reproducible than `skopeo copy` at script time.
**Counter-hypothesis tested:** Checked project `Containerfile` for akmods ARGs — none. Checked CI workflow for akmods digest resolution — none. Checked `ublue/Containerfile` and `ublue/Justfile` — the pattern exists and is fully implemented upstream.

### F2: 🔴 Single-maintainer COPR is the sole COSMIC upgrade path

**Severity:** high
**Evidence:** `build_files/base/05-cosmic-upgrade.sh:13` — `COPR_REPO="https://copr.fedorainfracloud.org/coprs/adil192/cosmic-epoch/repo/fedora-44/..."`. This is a single person's COPR (adil192). The repo is added, packages upgraded, and repo removed — all in one script with no mirror.
**Why it matters:** Bus factor of 1. If the maintainer stops updating or the COPR is deleted, COSMIC desktop is stuck at Fedora 44's bundled version (1.1.0). There is no fallback, no mirror, and no alternative upgrade path.
**Counter-hypothesis tested:** Searched for alternative COSMIC upgrade sources — none. The Fedora 44 repos ship COSMIC 1.1.0; only this COPR provides newer builds. Checked the COPR URL for version pinning — it's hardcoded to fedora-44, which means when Fedora 45 arrives, the URL must be manually updated.

### F3: 🟠 `copr_install_isolated` has no retry — packages silently fail

**Severity:** medium
**Evidence:** `build_files/shared/copr-helpers.sh:1-22` — the `copr_install_isolated` function has zero retry logic. Compare with `build_files/base/04-packages.sh:91` where Tailscale gets a 3x retry loop. The `uupd` package (runtime-fatal) is installed via `copr_install_isolated` at `04-packages.sh:102` with no retry.
**Why it matters:** If COPR infrastructure is temporarily unavailable during build, `uupd` silently fails to install. The image builds successfully but boots without automatic updates. There's no build-time warning and no runtime indication.
**Counter-hypothesis tested:** Read the full `copr_install_isolated` function — it enables, installs, and disables with no error handling beyond `set -euo pipefail`. Checked `04-packages.sh` for retry patterns — only Tailscale has one.

### F4: 🟡 Homebrew installed via fetched script from HEAD

**Severity:** medium
**Evidence:** `system_files/shared/usr/libexec/ublue-os/brew-setup:5` — `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true`. The `|| true` guard means failure is silent — if GitHub is unreachable or the script is compromised, Homebrew silently fails to install with no user-visible error.
**Why it matters:** This is the standard Homebrew install method and runs at first boot (user-triggered, not automated). However, it's a supply-chain concern — the script at HEAD can change at any time. The `|| true` guard was likely added because Homebrew install can fail for user-environment reasons and shouldn't block boot, but it also masks fetch failures and script errors.
**Counter-hypothesis tested:** Checked if the installer script could be vendored — it's a generated script, not a source artifact. The Homebrew project recommends this method. The rationale for `|| true` is not documented in the file — it may be for the FCA base gotcha (services may not exist) or for general Homebrew install fragility.

### F5: 🟡 `cosign` not explicitly installed in CI — implicit dependency on runner

**Severity:** medium
**Evidence:** `.github/workflows/build.yml:84-89` uses `cosign sign` but never installs cosign. The workflow relies on `ubuntu-latest` having it pre-installed. If cosign is absent, the step fails with a non-zero exit code — the failure is observable in CI (red X on the workflow run), but the image has already been built and pushed by that point.
**Why it matters:** If GitHub removes cosign from the runner image, the signing step fails observably in CI — but after the image is already pushed. The conditional (`if: github.ref == 'refs/heads/main'`) means this only affects main-branch builds. An unsigned image would still be pushed to the registry.
**Counter-hypothesis tested:** Searched `build.yml` for any cosign installation step — none. The step has no `|| true` guard, so a missing binary produces a non-zero exit and a visible CI failure.

### F6: 🟡 Bootstrap browser URLs are all mutable and unversioned

**Severity:** low
**Evidence:** `system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just:44` (Chrome: `google-chrome-stable_current`), line 55 (Brave: `releases/latest/download`), line 66-67 (VS Code: `?build=stable&os=linux-x64`). All three redirect to the latest version.
**Why it matters:** Non-deterministic bootstraps. Two users running `ujust bootstrap` on different days get different browser versions. This is acceptable for convenience scripts but means there's no way to reproduce a specific bootstrap state.
**Counter-hypothesis tested:** Checked if any version-pinned alternatives exist — none. The `~/.opt` pattern (rpm2cpio extraction) inherently avoids package manager conflicts, but the download URLs being mutable means the extracted versions are unpredictable.

### F7: 🟢 Two justfiles with diverged recipes — only one is active

**Severity:** low
**Evidence:** `system_files/shared/usr/share/ublue-os/just/60-custom.just:1-100` and `system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just:1-116`. Both serve the same purpose (custom ujust recipes) but with diverged implementations:
- `60-custom.just` uses namespaced recipe names (`fca-bootstrap`, `fca-info`, `rebase-helper`) and Flatpak for browsers
- `fedora-cosmic-atomic-dx.just` uses bare recipe names (`bootstrap`, `info`, `update`) and `~/.opt` rpm2cpio extraction for browsers
**Why it matters:** The `justfiles/` variant with `~/.opt` installs appears to be the intended direction (per `docs/research/vscode-install-strategy.md`), but `ujust` imports from `/usr/share/ublue-os/just/` — the `justfiles/` directory is not in the import path. The `60-custom.just` (Flatpak-based) variant is the one actually active. The `justfiles/` variant may be dead code.
**Counter-hypothesis tested:** Verified recipe names are different across files — no actual collision. Checked the ujust import chain — `ujust` → `just --justfile /usr/share/ublue-os/justfile` → `import? '60-custom.just'`. The `justfiles/` directory is not imported.

### F8: 🔴 Bootstrap uses rpm2cpio extraction — breaks immutable filesystem idiom

**Severity:** high
**Evidence:** `system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just:44-50` (Chrome) and lines 55-60 (Brave) — both use `rpm2cpio /tmp/chrome.rpm | (cd ~/.opt && cpio -idmv)` to extract RPMs into `~/.opt`. This installs browser binaries into the user's home directory at bootstrap time, bypassing both the rpm-ostree layer and Flatpak.
**Why it matters:** Atomic desktops guarantee that `/usr` is read-only and system state is managed by rpm-ostree. The `~/.opt` rpm2cpio pattern creates unmanaged, unversioned binaries in the user's home directory — there's no update mechanism, no integrity verification, and no rollback. The original Flatpak-based approach in `60-custom.just` respected the immutable idiom. The pivot to `~/.opt` (documented at `docs/research/vscode-install-strategy.md`) was made for credential persistence reasons but introduced a worse architectural problem. Chrome 150+'s `--password-store=gnome-libsecret` and the COSMIC keyring portal fix (`20-cosmic-keyring-fix.sh`) should make Flatpak credential persistence viable.
**Counter-hypothesis tested:** Checked if `~/.opt` binaries are tracked or updatable — they are not. No `rpm-ostree` layer, no Flatpak, no version pinning. The bootstrap script downloads the latest version each time, but there's no mechanism to update already-extracted binaries. Checked the COSMIC keyring fix at `build_files/base/20-cosmic-keyring-fix.sh` — it patches the XDG portal for COSMIC compatibility, which should resolve the credential persistence issue that motivated the pivot.

### F9: 🟡 `vscode.repo` validated but origin unknown

**Severity:** medium
**Evidence:** `build_files/shared/validate-repos.sh:55` checks that `vscode.repo` is disabled. This repo is not created by any of our build scripts. In the bluefin submodule, `bluefin/build_files/dx/00-dx.sh:89` creates it, but our `dx/00-dx.sh` does not. The repo either comes from the FCA base image (dependency not catalogued) or the validation check is dead code inherited from bluefin.
**Why it matters:** If `vscode.repo` comes from the base image, it should be in the RPM repo inventory. If it's dead validation code, it should be removed to avoid confusion. Either way, a dependency audit should account for it.
**Counter-hypothesis tested:** Searched our `build_files/` for any script that creates `vscode.repo` — none found. Checked bluefin for the creation script — found at `bluefin/build_files/dx/00-dx.sh:89`.

### F10: 🟡 Two Flathub URLs used inconsistently

**Severity:** low
**Why it matters:** Minimal — both are CDN-backed and reliable. Inconsistency is the only issue.
**Counter-hypothesis tested:** Verified both URLs resolve and are functional. Both point to the same Flathub repository.

## Patterns Observed

1. **Digest-pinning inconsistency**: The base image and brew layer use a mature digest-pinning pattern (`ARG` + CI resolution). The akmods images don't. The same CI pattern should apply to all OCI image fetches.

2. **COPR fragility**: Three COPRs are used, two are runtime-critical, none have retry logic or mirroring. COPRs don't guarantee immutable history — if a package is removed, old builds become non-reproducible.

3. **Bootstrap non-determinism**: All user-facing bootstrap URLs are mutable (browsers, VS Code, Homebrew). This is acceptable for a convenience script but limits reproducibility.

4. **Silent failure pattern**: `|| true` guards appear in two contexts: (a) `clean-stage.sh:12-13` and `build.sh:18-22` — legitimate `systemctl`/`dnf`/`rpm` guards per the AGENTS.md FCA base gotcha (services/packages may not exist on FCA base), and (b) `brew-setup:5` — a fetched script execution where `|| true` masks fetch failures and install errors with no logging. These are different failure modes requiring different mitigations: the systemctl guards are correct; the brew-setup guard should at minimum log the failure.

## Explicitly Checked and Found Clean

- **Base image digest pinning** (`Containerfile:1-6`, `build.yml:46-50`): Correctly implemented — mutable tag for local dev, digest-pinned in CI. Sufficient.
- **Brew image digest pinning** (`Containerfile:1-6`, `build.yml:52-56`): Same pattern. Sufficient.
- **Git submodules** (`.gitmodules`, `build.yml:29-30`): All three are commit-pinned and checked out recursively in CI. Sufficient.
- **RPMFusion repos** (`03-install-kernel-akmods.sh:46-49`): Installed, used, and removed in same script. Ephemeral pattern is correct.
- **Fedora base repos**: Implicit from base image, backed by Fedora's global mirror infrastructure. Sufficient.
- **Tailscale repo** (`04-packages.sh:91`): Has retry loop (3x). Good pattern.
- **`dnf5`, `skopeo`, `jq`, `flatpak`**: All provided by the FCA base image. No action needed.
- **Disabled repos** (`17-cleanup.sh`): Correctly disabled at build time. No action needed.
- **`actions/checkout@v4`**: Standard practice for GitHub-owned actions. Sufficient.

## Recommendations

### R1: Adopt the ublue submodule's FROM-based akmods pattern (F1)

The `ublue/` submodule at `ublue/Containerfile:8-19` already implements digest-pinned akmods image fetch using `FROM` + Null Object pattern (`${AKMODS_DIGEST:+@${AKMODS_DIGEST}}`), with digest resolution from `ublue/Justfile:165-166` via `image-versions.yaml`. This is the same pattern used for base/brew images and is more reproducible than our current `skopeo copy` approach. Adopt it instead of bolting digest-pinning onto `skopeo copy`.

### R2: Mirror the COSMIC COPR or negotiate upstream inclusion (F2)

The `adil192/cosmic-epoch` COPR is a single point of failure for COSMIC desktop upgrades.
- **Preferred:** Work with COSMIC upstream to get newer builds into official Fedora repos.
- **Fallback:** Mirror the RPMs into a project-controlled OCI image (like akmods does) and install from the mirror.
- **Minimum:** Document the dependency and bus factor explicitly.

### R3: Add retry to `copr_install_isolated` (F3)

Add a retry loop (3 attempts, 10s sleep) to the `copr_install_isolated` function in `copr-helpers.sh`. The `uupd` package is runtime-critical and currently has zero fault tolerance.

### R4: Consider vendoring the Homebrew installer (F4)

Ship a known-good version of the Homebrew install script in `system_files/` rather than fetching from HEAD at first boot. Update periodically. This eliminates a runtime supply-chain variable.

### R5: Explicitly install `cosign` in CI (F5)

Add `uses: sigstore/cosign-installer@v3` before the signing step. This removes the implicit dependency on `ubuntu-latest` including cosign.

### R6: Add retry to Docker CE repo fetch (F12)

Docker is a key DX feature. Add the same 3x retry loop used for Tailscale.

### R7: Resolve justfile divergence (F7)

`60-custom.just` (namespaced names, Flatpak browsers) is the active file via ujust import. `fedora-cosmic-atomic-dx.just` (bare names, `~/.opt` browsers) is not in the import path. Decide which direction is intended: if `~/.opt` is the future, update `60-custom.just` and remove the `justfiles/` variant. If Flatpak is staying, remove the dead `justfiles/` file.

### R8: Pin bootstrap URLs for reproducibility (F6)

Add version-pinned alternatives for Chrome, Brave, and VS Code. Keep the `current`/`latest` URLs as defaults, but document the pinned alternatives for reproducible bootstraps.

### R9: Standardize Flathub URL (F10)

Use a single Flathub URL consistently across all files.

### R10: Investigate vscode.repo origin (F9)

Determine whether `vscode.repo` comes from the FCA base image (catalogue it) or is dead validation inherited from bluefin (remove the `validate-repos.sh:55` check).

### R11: Revert browser installs to Flatpak — the `~/.opt` rpm2cpio pattern breaks the atomic idiom (F8)

The `rpm2cpio` extraction into `~/.opt` creates unmanaged, unversioned binaries that bypass rpm-ostree and Flatpak. The COSMIC keyring portal fix (`20-cosmic-keyring-fix.sh`) should resolve the credential persistence issue that motivated the pivot. Revert Chrome and Brave installs to Flatpak in `60-custom.just`. If Flatpak credential persistence still fails, investigate `oo7-daemon`/`oo7-portal` rather than breaking the immutable filesystem contract. The `justfiles/fedora-cosmic-atomic-dx.just` `~/.opt` variant should be either deleted or explicitly marked as unsupported.

## External Research Needed

- [ ] Is `cosign` guaranteed to be on `ubuntu-latest`? If not, should be explicitly installed (R5).
- [ ] What is the upstream COSMIC packaging roadmap? Are newer builds planned for official Fedora repos? (informs R2)
- [ ] Are there any existing Fedora/CentOS mirroring patterns for COPR repos that this project could adopt?
