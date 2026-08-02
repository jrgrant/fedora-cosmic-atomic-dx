#!/usr/bin/env bats
# s5-cosign-ci.bats — Structural test for S5 cosign explicit installation in CI
#
# Verifies that sigstore/cosign-installer@v3 is added before the cosign sign step.
#
# Spec: docs/superpowers/specs/2026-08-02-upstream-dependency-catalog-recommendations.md S5
# FR-S5-1

CI_WORKFLOW=".github/workflows/build.yml"

@test "T1: cosign-installer action present in build workflow" {
    run grep 'sigstore/cosign-installer@v3' "$CI_WORKFLOW"
    [ "$status" -eq 0 ]
}

@test "T2: cosign-installer appears before cosign sign step" {
    # The installer must come before the sign step in the file
    installer_line=$(grep -n 'sigstore/cosign-installer@v3' "$CI_WORKFLOW" | head -1 | cut -d: -f1)
    sign_line=$(grep -n 'cosign sign' "$CI_WORKFLOW" | head -1 | cut -d: -f1)
    [ "$installer_line" -lt "$sign_line" ]
}

@test "T3: CI test glob matches all bats files" {
    run grep "bats tests/bats/\*.bats" "$CI_WORKFLOW"
    [ "$status" -eq 0 ]
}
