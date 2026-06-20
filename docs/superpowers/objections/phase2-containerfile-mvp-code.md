---
spec: docs/superpowers/specs/2026-06-20-phase2-containerfile-mvp-design.md
date: 2026-06-20
mode: code
diaboli_model: deepseek-v4-pro
objections:
  - id: CO1
    category: implementation
    severity: medium
    claim: The brew-setup stub unconditionally runs the Homebrew installer — if the network is unavailable at first boot, brew-setup.service fails silently with no retry mechanism
    evidence: "system_files/shared/usr/libexec/ublue-os/brew-setup: 'curl -fsSL ... || true'. The '|| true' swallows the error. The service has no Restart=on-failure in its unit file. brew-setup.service will show as 'active (exited)' with code 0 even if curl failed. The user gets no indication that Homebrew was never installed."
    disposition: accepted
    disposition_rationale: Real user pain — silent Homebrew failure. Fix: add Restart=on-failure, RestartSec=30 to brew-setup.service.
  - id: CO2
    category: implementation
    severity: medium
    claim: The kernel removal loop in 03-install-kernel-akmods.sh uses --nodeps which could break the image if any new kernel subpackage is added upstream and not caught by our package list
    evidence: "build_files/base/03-install-kernel-akmods.sh: 'for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do rpm --erase $pkg --nodeps; done'. Bluefin's version uses the same loop (read from earlier in session). If Fedora adds a new kernel subpackage (e.g., kernel-modules-uki), it won't be removed, and the subsequent kernel install could conflict. This is inherited technical debt from Bluefin, but we're carrying it without noting the risk."
    disposition: deferred
    disposition_rationale: Inherited Bluefin debt. If Fedora adds a kernel subpackage, Bluefin's build fails first and they fix upstream. Track their fix.
  - id: CO3
    category: risk
    severity: low
    claim: No Containerfile tests verify that the image actually builds — all 41 tests are source-level grep checks; a typo in a package name would pass all tests but fail at podman build
    evidence: "All 41 bats tests verify file existence and string presence in source files. No test runs 'podman build' or 'bootc container lint'. The spec's US1 acceptance scenario 'podman build completes without error' is not tested. This is noted in O3 (spec diaboli, accepted — build-time verification also includes structural checks) but the structural checks are the ONLY checks. A podman build test would catch package name typos, script syntax errors, and missing dependencies."
    disposition: accepted
    disposition_rationale: Podman build test is a Phase 3 concern (CI pipeline). Accepted in principle — implement when CI is set up.
  - id: CO4
    category: specification quality
    severity: low
    claim: The build scripts reference /ctx/ paths and the Containerfile mounts /ctx — these assumptions are not documented anywhere outside the Containerfile
    evidence: "Containerfile: '--mount=type=bind,from=ctx,source=/,target=/ctx'. build.sh: '/ctx/build_files/shared/build.sh'. If someone tries to run build.sh outside of a Containerfile build context, the script fails with '/ctx not found'. The spec doesn't mention this constraint. A one-line comment in build.sh would prevent confusion."
    disposition: deferred
    disposition_rationale: /ctx assumption is inherent to all UBlue Containerfile builds. Add a comment to build.sh.
  - id: CO5
    category: risk
    severity: low
    claim: clean-stage.sh removes /boot and /var aggressively — if FCA's base image structure differs from Silverblue's, this could break the image
    evidence: "build_files/shared/clean-stage.sh: 'rm -rf /boot && mkdir -p /boot' and 'find /var/* -maxdepth 0 -type d \\! -name cache -exec rm -fr {} \\;'. This is copied verbatim from Bluefin. Bluefin targets Silverblue, which is known to not need /boot content after ostree commit. FCA may store bootloader data differently. Removing /boot content could make the image unbootable on some hardware/firmware configurations."
    disposition: deferred
    disposition_rationale: FCA and Silverblue share common.yaml — same ostree/bootc layout. If boot fails, we'll see it in Phase 5 (dogfood). Premature fix.

---

## Explicitly not objecting to

1. **The package selection** — matches the dx inventory exactly and was thoroughly researched
2. **The GNOME stripping approach** — removing packages and services rather than forking scripts is the right call for maintainability
3. **The Containerfile structure** — follows Bluefin's proven pattern with digest pinning
4. **The bats test suite** — 41 well-structured tests, proper use of the framework
5. **The service enablement** — all enabled services are desktop-agnostic and documented in the spec
6. **Shellcheck and gitleaks** — both pass clean
