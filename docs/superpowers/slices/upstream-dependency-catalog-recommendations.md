---
task: Implement 11 recommendations from the upstream dependency catalog research
task_slug: upstream-dependency-catalog-recommendations
date: 2026-08-02
carpaccio_model: gpt-5.1-carpaccio
inseparable: false
progressed_slice: S6
slices:
- id: S1
  title: Adopt ublue submodule FROM-based akmods pattern
  scope: Containerfile and build_files/base/03-install-kernel-akmods.sh — replace skopeo copy with FROM + --mount pattern
    from ublue/Containerfile:8-19, adding AKMODS_DIGEST and AKMODS_NVIDIA_DIGEST ARGs with Null Object pattern
  decision_focus: Adopt the upstream FROM-based pattern now (higher reproducibility, same digest-pinning as base/brew images)
    or defer (keep working skopeo copy, revisit when akmods images cause a reproducibility incident)?
  lens_used: decision-boundary
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02
  file_as_issue: true
  issue_url: https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/55
  merged_into: null
- id: S2
  title: Mitigate COSMIC COPR single-maintainer bus factor
  scope: Documentation and/or infrastructure for adil192/cosmic-epoch COPR dependency — negotiate upstream inclusion, mirror
    RPMs into project-controlled storage, or document the risk explicitly
  decision_focus: 'Which tier of mitigation to pursue: negotiate with COSMIC upstream for official Fedora packaging (best,
    uncertain timeline), mirror the COPR RPMs into a project-controlled OCI image (medium effort, immediate safety), or document
    the dependency and bus factor as accepted risk (minimum effort, no protection)?'
  lens_used: decision-boundary
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02
  file_as_issue: true
  issue_url: https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/56
  merged_into: null
- id: S3
  title: Add retry loops to copr_install_isolated and Docker CE repo fetch
  scope: build_files/shared/copr-helpers.sh (copr_install_isolated function) and build_files/dx/00-dx.sh:81 (Docker CE repo
    fetch) — add 3x retry with 10s sleep, pattern from Tailscale at build_files/base/04-packages.sh:91
  decision_focus: 'No material decision — both are implementation of a known pattern already established in the codebase.
    The acceptance criterion is: CI build survives transient COPR infrastructure and Docker download mirror outages.'
  lens_used: acceptance-criterion
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02 — implementation-only, no separate issue needed
  file_as_issue: false
  issue_url: null
  merged_into: null
- id: S4
  title: Decide Homebrew installer vendoring strategy
  scope: system_files/shared/usr/libexec/ublue-os/brew-setup — either vendor a known-good installer script in system_files/
    (with documented update cadence) or document the rationale for continuing to fetch from HEAD with explicit logging of
    failures instead of silent || true
  decision_focus: Vendor the Homebrew installer script (supply-chain control, maintenance burden of periodic updates) or keep
    fetching from HEAD with improved failure logging (less maintenance, accepts upstream mutability)?
  lens_used: decision-boundary
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02
  file_as_issue: true
  issue_url: https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/57
  merged_into: null
- id: S5
  title: Explicitly install cosign in CI
  scope: .github/workflows/build.yml — add sigstore/cosign-installer@v3 action before the cosign sign step, removing implicit
    dependency on ubuntu-latest runner image providing cosign
  decision_focus: 'No material decision — the research confirms cosign is not guaranteed on ubuntu-latest and the fix (sigstore/cosign-installer@v3)
    is standard practice. The acceptance criterion is: CI signing step passes without relying on a preinstalled cosign binary.'
  lens_used: acceptance-criterion
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02 — implementation-only, no separate issue needed
  file_as_issue: false
  issue_url: null
  merged_into: null
- id: S6
  title: Consolidate justfile divergence and choose browser install mechanism
  scope: system_files/shared/usr/share/ublue-os/just/60-custom.just and system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just
    — resolve the two-file divergence by choosing Flatpak (60-custom.just direction, respects atomic idiom, delete justfiles/
    variant) or ~/.opt rpm2cpio extraction (justfiles/ direction, better credential persistence, update 60-custom.just to
    match)
  decision_focus: 'Which browser install mechanism for the project: Flatpak (immutable-idiom-respecting, credential persistence
    should work after COSMIC keyring fix) or ~/.opt rpm2cpio extraction (convenience, but creates unmanaged unversioned binaries
    in home directory, breaks atomic filesystem contract)? This decision also determines which justfile survives.'
  lens_used: decision-boundary
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02 — progressed slice
  file_as_issue: false
  issue_url: null
  merged_into: null
- id: S7
  title: Pin bootstrap URLs for reproducibility and standardize Flathub URL
  scope: system_files/shared/usr/share/ublue-os/just/60-custom.just — add version-pinned alternatives as comments for Chrome,
    Brave, and VS Code download URLs; standardize Flathub URL to a single flathub.org variant
  decision_focus: 'How to provide reproducibility for bootstrap URLs: add comments with pinned version URLs alongside mutable
    defaults (low effort, human opt-in), create a separate reproducible-bootstrap target with pinned URLs (medium effort,
    explicit opt-in), or change defaults to pinned URLs (high effort, requires update discipline)?'
  lens_used: decision-boundary
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02 — depends on S6, implement inline
  file_as_issue: false
  issue_url: null
  merged_into: null
- id: S8
  title: Investigate and dispose of vscode.repo validation
  scope: build_files/shared/validate-repos.sh:55 — determine whether vscode.repo originates from the FCA base image (catalogue
    it in the dependency inventory) or is dead validation inherited from bluefin (remove the check)
  decision_focus: 'After investigation: catalogue vscode.repo as a base-image dependency (acknowledge it exists and is intentionally
    disabled) or remove the validation check (confirm it''s dead code inherited from bluefin, where dx/00-dx.sh creates it
    but our dx/00-dx.sh does not)?'
  lens_used: decision-boundary
  disposition: accepted
  disposition_rationale: Approved at Slice Adjudication Gate 2026-08-02
  file_as_issue: true
  issue_url: https://github.com/jrgrant/fedora-cosmic-atomic-dx/issues/58
  merged_into: null
---
