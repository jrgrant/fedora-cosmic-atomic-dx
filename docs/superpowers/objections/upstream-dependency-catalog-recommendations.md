---
spec: docs/superpowers/specs/2026-08-02-upstream-dependency-catalog-recommendations.md
date: 2026-08-02
mode: spec
diaboli_model: deepseek-v4-pro
objections:
  - id: O1
    category: premise
    severity: high
    claim: "The spec's central justification — that the COSMIC keyring fix resolves Flatpak browser credential persistence — is presented as 'should resolve' without end-to-end verification, which the spec explicitly excludes."
    disposition: accepted
    disposition_rationale: "Browser secret persistence has been verified to work with Flatpak installs (confirmed by user). The 'should' language in the spec will be strengthened to 'does.'"
  - id: O2
    category: scope
    severity: high
    claim: "The spec provides no migration or cleanup path for users who already ran the rpm2cpio bootstrap and have ~/.opt binaries."
    disposition: accepted
    disposition_rationale: "A cleanup note will be added to the bootstrap recipe suggesting removal of ~/.opt browser directories and ~/.local/bin symlinks if switching from rpm2cpio."
  - id: O3
    category: implementation
    severity: high
    claim: "The 2>/dev/null || true pattern on flatpak install commands causes silent failures — the spec formalizes this without addressing error handling."
    disposition: accepted
    disposition_rationale: "Error handling will be improved: replace 2>/dev/null || true with a check after each install that logs success/failure, keeping || true only for the pre-check guards."
  - id: O4
    category: risk
    severity: high
    claim: "Deleting fedora-cosmic-atomic-dx.just removes the only documented fallback before verifying Flatpak credential persistence works."
    disposition: accepted
    disposition_rationale: "Credential persistence verified. The dead justfile will be moved to docs/archive/ rather than deleted, preserving institutional knowledge."
  - id: O5
    category: alternatives
    severity: medium
    claim: "VS Code via brew cask was recommended by prior research but the spec bundles it with browsers under Flatpak without addressing tradeoffs."
    disposition: accepted
    disposition_rationale: "VS Code will be installed via 'brew install --cask visual-studio-code-linux' per prior research, not Flatpak. Only Chrome and Brave move to Flatpak."
  - id: O6
    category: specification quality
    severity: medium
    claim: "FR-S6-7 and FR-S6-8 describe current behavior of 20-cosmic-keyring-fix.sh as if they were new requirements — an implementer cannot tell if modification is required."
    disposition: accepted
    disposition_rationale: "FRs will be reworded as verification checks: 'The COSMIC keyring fix script at build_files/base/20-cosmic-keyring-fix.sh must continue to patch...'"
  - id: O7
    category: specification quality
    severity: medium
    claim: "No FR or acceptance scenario covers install command failure behavior — the spec permits a bootstrap that silently fails."
    disposition: accepted
    disposition_rationale: "New acceptance scenario: bootstrap logs success/failure for each Flatpak install. FR added: each install must produce user-visible output indicating success or failure."
  - id: O8
    category: risk
    severity: medium
    claim: "The flatpak remote-add --if-not-exists flathub command also uses 2>/dev/null || true — if it fails, all three app installs fail silently."
    disposition: accepted
    disposition_rationale: "Remote-add will be followed by a 'flatpak remotes | grep flathub' verification check before proceeding to app installs."
  - id: O9
    category: scope
    severity: medium
    claim: "The two justfiles diverge on more than browser install mechanisms — 60-custom.just includes COSMIC keyring env setup and dbus activation that must be retained."
    disposition: accepted
    disposition_rationale: "Spec will note that cosmic-keyring-env.service enablement and dbus-update-activation-environment --systemd WAYLAND_DISPLAY must be preserved in the consolidated justfile."
  - id: O10
    category: alternatives
    severity: medium
    claim: "Rather than deleting fedora-cosmic-atomic-dx.just, archive it to docs/archive/ to preserve institutional knowledge."
    disposition: accepted
    disposition_rationale: "File will be moved to docs/archive/fedora-cosmic-atomic-dx.just with a header comment explaining it's the deprecated rpm2cpio bootstrap path."
---

# Adversarial Review — Spec Mode

## Verdict: FINDINGS (10) — 4 high, 6 medium, 0 critical

All accepted with remediations noted. No blocking issues. Pipeline continues.
