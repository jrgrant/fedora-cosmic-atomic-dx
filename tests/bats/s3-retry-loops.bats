#!/usr/bin/env bats
# s3-retry-loops.bats — Structural tests for S3 retry loop implementation
#
# Verifies that retry loops were added to copr_install_isolated (copr-helpers.sh)
# and Docker CE repo fetch (dx/00-dx.sh), following the Tailscale pattern at
# build_files/base/04-packages.sh:91.
#
# Spec: docs/superpowers/specs/2026-08-02-upstream-dependency-catalog-recommendations.md S3
# FR-S3-1 through FR-S3-4

COPR_HELPERS="build_files/shared/copr-helpers.sh"
DX_SCRIPT="build_files/dx/00-dx.sh"

# =============================================================================
# Scenario 1: copr_install_isolated has retry loop (FR-S3-1, FR-S3-2)
# =============================================================================

@test "T1: copr_install_isolated has retry loop with max_retries variable" {
    run grep 'max_retries=3' "$COPR_HELPERS"
    [ "$status" -eq 0 ]
}

@test "T2: copr_install_isolated retries on failure with sleep" {
    run grep 'sleep 10' "$COPR_HELPERS"
    [ "$status" -eq 0 ]
}

@test "T3: copr_install_isolated returns error after exhausting retries" {
    run grep 'ERROR: Failed to install' "$COPR_HELPERS"
    [ "$status" -eq 0 ]
}

@test "T4: copr_install_isolated retry pattern references Tailscale source" {
    run grep 'Pattern from Tailscale' "$COPR_HELPERS"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Scenario 2: Docker CE repo fetch has retry loop (FR-S3-3)
# =============================================================================

@test "T5: Docker CE repo fetch has for 1 2 3 retry loop" {
    run grep 'for i in 1 2 3' "$DX_SCRIPT"
    [ "$status" -eq 0 ]
}

@test "T6: Docker CE retry loop has sleep and break on success" {
    run grep 'sleep 10' "$DX_SCRIPT"
    [ "$status" -eq 0 ]
}
