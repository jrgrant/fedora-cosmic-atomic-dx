#!/usr/bin/env bats
# Submodule strategy recommendations — structural validation tests
#
# Covers spec: docs/superpowers/specs/2026-08-02-submodule-recommendations.md
#
# Test groups:
#   T1-T3:   m2os submodule removed (R1/US1)
#   T4-T8:   adaptations.yaml bill of materials (R2/US2)
#   T9-T11:  CI digest pinning (R3/US3)
#   T12-T15: HARNESS.md Lifecycle column (R4/US4)
#   T16-T19: ADR flat-submodule-structure (R5/US5)
#
# All tests are structural — shell commands, yaml.safe_load, grep assertions.
# No compiled code.  Every test is expected to fail (RED) before implementation.

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

# =============================================================================
# R1/US1 — Remove m2os submodule
# =============================================================================

# T1 — FR1: .gitmodules must not contain [submodule "m2os"]
@test "T1: .gitmodules has no m2os submodule entry" {
    run grep -c '\[submodule "m2os"\]' "$PROJECT_ROOT/.gitmodules"
    # grep -c returns 0 when no matches; exits 1 when no matches found.
    # Both mean "m2os entry absent" — the test passes when the entry is gone.
    if [ "$status" -eq 1 ]; then
        # grep found no matches (exit 1), which is what we want
        return 0
    fi
    # grep found matches (exit 0); count must be zero
    [ "$output" = "0" ]
}

# T2 — FR2: m2os directory must not exist on disk
@test "T2: m2os directory is absent" {
    [ ! -d "$PROJECT_ROOT/m2os" ]
}

# T3 — FR3: HARNESS.md Reference Repos table has no m2os row
@test "T3: HARNESS.md Reference Repos table has no m2os row" {
    # The Reference Repos table spans from "| Submodule | Upstream | Purpose |"
    # through the next blank line or "---" section break.
    # This test confirms no m2os row appears in that table context.
    run grep -c 'm2os' "$PROJECT_ROOT/.claude/HARNESS.md"
    if [ "$status" -eq 1 ]; then
        return 0
    fi
    [ "$output" = "0" ]
}

# =============================================================================
# R2/US2 — adaptations.yaml bill of materials
# =============================================================================

# T4 — FR4: adaptations.yaml exists and parses as valid YAML
@test "T4: adaptations.yaml exists and is valid YAML" {
    [ -f "$PROJECT_ROOT/adaptations.yaml" ]
    run python3 -c "import yaml; yaml.safe_load(open('$PROJECT_ROOT/adaptations.yaml'))"
    [ "$status" -eq 0 ]
}

# T5 — FR5: adaptations.yaml has at least 5 entries
@test "T5: adaptations.yaml contains at least 5 adaptation entries" {
    run python3 -c "
import yaml
d = yaml.safe_load(open('$PROJECT_ROOT/adaptations.yaml'))
assert 'adaptations' in d, 'missing top-level adaptations key'
assert isinstance(d['adaptations'], list), 'adaptations must be a list'
assert len(d['adaptations']) >= 5, f'expected >=5 entries, got {len(d[\"adaptations\"])}'
"
    [ "$status" -eq 0 ]
}

# T6 — FR6: every adaptation entry has required fields (file, upstream, forked_at, notes)
@test "T6: every adaptation entry has required fields" {
    run python3 -c "
import yaml
d = yaml.safe_load(open('$PROJECT_ROOT/adaptations.yaml'))
REQUIRED = {'file', 'upstream', 'forked_at', 'notes'}
for i, entry in enumerate(d['adaptations']):
    missing = REQUIRED - set(entry.keys())
    assert not missing, f'entry {i} ({entry.get(\"file\", \"unknown\")}) missing: {missing}'
    for field in REQUIRED:
        assert entry[field], f'entry {i} ({entry.get(\"file\", \"unknown\")}): {field} is empty'
"
    [ "$status" -eq 0 ]
}

# T7 — FR7: every file path listed in adaptations.yaml exists on disk
@test "T7: every file path in adaptations.yaml exists on disk" {
    run python3 -c "
import yaml, os, sys
d = yaml.safe_load(open('$PROJECT_ROOT/adaptations.yaml'))
missing = []
for entry in d['adaptations']:
    path = os.path.join('$PROJECT_ROOT', entry['file'])
    if not os.path.isfile(path):
        missing.append(entry['file'])
if missing:
    sys.exit(f'missing files: {missing}')
"
    [ "$status" -eq 0 ]
}

# T8 — FR4 (structural): yamllint passes on adaptations.yaml
@test "T8: yamllint passes on adaptations.yaml" {
    [ -f "$PROJECT_ROOT/adaptations.yaml" ]
    run yamllint "$PROJECT_ROOT/adaptations.yaml"
    [ "$status" -eq 0 ]
}

# =============================================================================
# R3/US3 — Pin OCI base images by digest in CI
# =============================================================================

# T9 — FR8–FR12: CI workflow YAML parses cleanly after edits
@test "T9: CI workflow YAML is valid" {
    run python3 -c "import yaml; yaml.safe_load(open('$PROJECT_ROOT/.github/workflows/build.yml'))"
    [ "$status" -eq 0 ]
}

# T10 — FR8, FR9: CI workflow has at least 2 podman image inspect steps
# (Design decision from diaboli review: use podman image inspect, not skopeo)
@test "T10: CI workflow resolves both base images to digests via podman image inspect" {
    run grep -c 'podman image inspect' "$PROJECT_ROOT/.github/workflows/build.yml"
    if [ "$status" -eq 1 ]; then
        false  # no matches found — test fails
    fi
    [ "$output" -ge 2 ]
}

# T11 — FR10: CI workflow passes digest ARGs to the Containerfile via --build-arg
@test "T11: CI workflow references digest build-args (BREW_IMAGE_SHA or BASE_IMAGE_DIGEST)" {
    run grep -cE 'BREW_IMAGE_SHA|BASE_IMAGE_DIGEST' "$PROJECT_ROOT/.github/workflows/build.yml"
    if [ "$status" -eq 1 ]; then
        false  # no matches — test fails
    fi
    [ "$output" -ge 1 ]
}

# =============================================================================
# R4/US4 — Lifecycle column in HARNESS.md Reference Repos table
# =============================================================================

# T12 — FR13: HARNESS.md Reference Repos table has a Lifecycle column
@test "T12: HARNESS.md Reference Repos table has a Lifecycle column header" {
    run grep -c 'Lifecycle' "$PROJECT_ROOT/.claude/HARNESS.md"
    if [ "$status" -eq 1 ]; then
        false  # no matches — test fails
    fi
    [ "$output" -ge 1 ]
}

# T13 — FR14: fca row shows stable in Lifecycle column
@test "T13: fca row shows stable lifecycle" {
    # The Lifecycle column appears after Purpose in the table.
    # Look for a table row where fca appears and the Lifecycle cell contains "stable".
    # Pattern: fca row with `| stable |` as a distinct table cell.
    run grep -P 'fca.*\|\s*stable\s*\|' "$PROJECT_ROOT/.claude/HARNESS.md"
    [ "$status" -eq 0 ]
}

# T14 — FR15: ublue row shows active in Lifecycle column
@test "T14: ublue row shows active lifecycle" {
    run grep -P 'ublue.*\|\s*active\s*\|' "$PROJECT_ROOT/.claude/HARNESS.md"
    [ "$status" -eq 0 ]
}

# T15 — FR16: bluefin row shows active in Lifecycle column
@test "T15: bluefin row shows active lifecycle" {
    run grep -P 'bluefin.*\|\s*active\s*\|' "$PROJECT_ROOT/.claude/HARNESS.md"
    [ "$status" -eq 0 ]
}

# =============================================================================
# R5/US5 — ADR: flat submodule structure
# =============================================================================

# T16 — FR17: ADR file exists at expected path
# (Design decision: standalone file at docs/superpowers/adr/)
@test "T16: ADR file exists for flat-submodule-structure decision" {
    ADR_PATH="$PROJECT_ROOT/docs/superpowers/adr/2026-08-02-flat-submodule-structure.md"
    [ -f "$ADR_PATH" ]
}

# T17 — FR19: ADR has status: accepted in YAML frontmatter
@test "T17: ADR frontmatter has status: accepted" {
    ADR_PATH="$PROJECT_ROOT/docs/superpowers/adr/2026-08-02-flat-submodule-structure.md"
    [ -f "$ADR_PATH" ]
    run grep -c 'status:.*accepted' "$ADR_PATH"
    if [ "$status" -eq 1 ]; then
        false
    fi
    [ "$output" -ge 1 ]
}

# T18 — FR18: ADR includes rationale referencing project scale
@test "T18: ADR rationale references project scale (1.3MB, 3-4 submodules)" {
    ADR_PATH="$PROJECT_ROOT/docs/superpowers/adr/2026-08-02-flat-submodule-structure.md"
    [ -f "$ADR_PATH" ]
    # Look for scale-related rationale — submodule count or size mention
    run grep -cE '1\.3\s*MB|3.?4\s*submodules|submodules?\s*total' "$ADR_PATH"
    if [ "$status" -eq 1 ]; then
        false
    fi
    [ "$output" -ge 1 ]
}

# T19 — FR18: ADR mentions the directory-grouping alternative was considered and rejected
@test "T19: ADR mentions directory-grouping alternative considered and rejected" {
    ADR_PATH="$PROJECT_ROOT/docs/superpowers/adr/2026-08-02-flat-submodule-structure.md"
    [ -f "$ADR_PATH" ]
    run grep -cE 'directory.?group|upstream/.*group|group.*submodule|nested|flat' "$ADR_PATH"
    if [ "$status" -eq 1 ]; then
        false
    fi
    [ "$output" -ge 1 ]
}
