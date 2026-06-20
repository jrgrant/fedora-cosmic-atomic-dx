# CI Pipeline — Design Spec

**Date**: 2026-06-20
**Issue**: #6

## 1. Problem

Phase 2 produces a buildable Containerfile. We need automated CI that builds on FCA updates, runs tests, pushes to ghcr.io, and signs with cosign.

## 2. Design

### 2.1 Workflow triggers

- `schedule: daily` — catch new FCA tags
- `workflow_dispatch` — manual trigger
- `push` to `main` — rebuild on merges
- `pull_request` — test on PRs (no push)

### 2.2 Steps

1. **Checkout** — full repo including submodules
2. **Set up podman** — available on GitHub runners
3. **Pull base** — `cosmic-atomic:44` (cached)
4. **Build** — `podman build -t atomic-cosmic .`
5. **Structural tests** — `bats tests/bats/us*.bats`
6. **Build validation** — `BUILD_TEST=1 bats tests/bats/build-validation.bats`
7. **Push** — `podman push` to ghcr.io (main branch only)
8. **Sign** — `cosign sign` with private key (main branch only)

### 2.3 Tagging strategy

| Tag | Purpose |
|---|---|
| `44` | Current Fedora version (mutable, tracks latest build) |
| `44-YYYYMMDD` | Date-stamped, immutable |
| `latest` | Convenience pointer to most recent build |

### 2.4 Secrets

- `COSIGN_PRIVATE_KEY` — cosign key pair (user generates: `cosign generate-key-pair`)
- `GHCR_TOKEN` — optional, `GITHUB_TOKEN` has package write for the repo

## 3. User stories

### US1 — Automatic rebuild on FCA updates

**As** a user of atomic-cosmic
**I want** the image rebuilt when FCA publishes a new tag
**So that** I always get the latest COSMIC base with Bluefin tooling.

Acceptance: workflow runs daily, checks FCA tags, rebuilds if changed.

### US2 — PR validation

**As** a contributor
**I want** CI to build and test on every PR
**So that** broken Containerfiles are caught before merge.

Acceptance: PR workflow runs build + bats tests. No push to ghcr.io.

### US3 — Signed images

**As** a security-conscious user
**I want** images signed with cosign
**So that** I can verify provenance before booting.

Acceptance: `cosign verify` succeeds against published image.

## 4. Files

| File | Action |
|---|---|
| `.github/workflows/build.yml` | Create |
| `cosign.pub` | Create (public key committed) |

## 5. Exclusions

- Bootstrap script (Phase 4)
- README/install docs
- Multi-arch builds (future)
