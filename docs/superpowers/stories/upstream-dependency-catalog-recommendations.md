---
spec: docs/superpowers/specs/2026-08-02-upstream-dependency-catalog-recommendations.md
date: 2026-08-02
mode: spec
cartographer_model: deepseek-v4-pro
stories:
  - id: 1
    lens: [patterns]
    title: "Namespaced recipe names over bare upstream collisions"
    disposition: accepted
    disposition_rationale: "60-custom.just uses fca-bootstrap/fca-info/rebase-helper — avoids collision with upstream just recipes per AGENTS.md gotcha."
  - id: 2
    lens: [forces, patterns]
    title: "Flatpak for browsers, respecting the atomic idiom"
    disposition: accepted
    disposition_rationale: "Browser secret persistence verified working with Flatpak + COSMIC keyring fix. rpm2cpio ~/.opt pattern breaks immutable filesystem contract."
  - id: 3
    lens: [alternatives]
    title: "VS Code via brew cask, not Flatpak uniformity"
    disposition: accepted
    disposition_rationale: "brew cask was the prior research recommendation — proper desktop files, no sandbox flags, simpler. Flatpak VS Code has sandbox limitations for dev workflows."
  - id: 4
    lens: [patterns, consequences]
    title: "Archive dead justfile rather than delete it"
    disposition: accepted
    disposition_rationale: "Move to docs/archive/ with deprecation header. Preserves institutional knowledge of rpm2cpio pattern without leaving dead code in import path."
  - id: 5
    lens: [defaults, consequences]
    title: "COSMIC keyring env and dbus survive consolidation"
    disposition: accepted
    disposition_rationale: "cosmic-keyring-env.service enablement and dbus-update-activation-environment --systemd WAYLAND_DISPLAY are load-bearing for credential persistence. Must be preserved."
---

# Choice Stories — S6 Justfile Consolidation

5 stories, all accepted. No pending dispositions.
