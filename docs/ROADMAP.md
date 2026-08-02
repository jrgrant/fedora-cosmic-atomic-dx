# Roadmap: FCA Developer Experience

**Updated**: 2026-07-17
**Target**: Fedora COSMIC Atomic + Bluefin developer tooling as a custom OCI image

---

## Phase 0 — Foundation ✅
- [x] PROBLEM.md, submodules, harness, constraint tools, research

## Phase 1 — Diff the Gap ✅
- [x] Bluefin dx inventory, system_files audit, services audit, FCA baseline, COSMIC-specific needs

## Phase 2 — Containerfile MVP ✅
- [x] Containerfile, ported build scripts, Homebrew layer, Flathub, COSMIC 1.3.0 upgrade
- [x] Keyring fixes: portal `UseIn=COSMIC`, autostart `OnlyShowIn=COSMIC`, D-Bus env
- [x] akmods kernel + NVIDIA, local build passes

## Phase 3 — CI Pipeline ✅
- [x] GitHub Actions workflow, smoke tests, container push

## Phase 4 — Bootstrap & Ujust ✅
- [x] Homebrew taps, starship, distrobox, Flatpak user apps (Chrome/Brave/VSCode)
- [x] `ujust bootstrap/info/rebase-helper/rollback`, `Justfile`

## Phase 5 — Dogfood & Harden ✅
- [x] Booted on own machine, all tools functional
- [x] Session persistence working (Flatpak + basic store, no keyring needed)
- [x] Build fixes: digest rebase, tailscale retry, `First Run` cleanup

## Phase 6 — Maintain & Upstream (current)
1. [x] Stable CI — re-enable scheduled builds
2. [ ] Boot tests — automate validation
3. [ ] Watch F45 + oo7 — drop keyring patches when oo7 lands (~Oct 2026)
4. [ ] Quarterly harness audit
5. [x] README with install instructions

---

## Lessons Learned

| Lesson | Detail |
|--------|--------|
| Chrome 150 + COSMIC = no keyring | `freedesktop_secret_key_provider.cc` silently fails; portal backend broken |
| `~/.opt` hacks are a dead end | Flatpak handles desktop files, icons, updates, portal integration |
| FCA ≠ Silverblue | `/opt` immutable, missing services, COPR needs `ID=fedora` |
| rpm-ostree needs digest rebase | Same tag = "refs are equal" → use `@sha256:...` |
| ujust recipe names silently collide | `allow-duplicate-recipes` means no error |
| `First Run` sentinel breaks Chrome | Corrupted m2os profile; fresh + `--no-first-run` fixes |
| oo7 is the future (F45) | Our portal/autostart patches are temporary |
