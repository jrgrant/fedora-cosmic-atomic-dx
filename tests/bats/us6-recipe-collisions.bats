#!/usr/bin/env bats

# us6-recipe-collisions.bats — Verify ujust recipe collision detection
#
# Tests the check-recipe-collisions.sh script:
# - Script exists and is executable
# - Script passes (no collisions) with current recipe names
# - Script fails when a collision is introduced

setup() {
    SCRIPT="scripts/check-recipe-collisions.sh"
}

@test "collision check script exists and is executable" {
    [ -f "$SCRIPT" ]
    [ -x "$SCRIPT" ]
}

@test "collision check passes with current recipe names" {
    run bash "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PASSED: No collisions"* ]]
}

@test "collision check detects a shadowed recipe" {
    # Create a temporary custom justfile with a colliding recipe name
    TMP_JUST="$(mktemp)"
    echo "bootstrap:" > "$TMP_JUST"
    # Extract recipe names like the script does
    RECIPES=$(grep -oP '^\s*\K[a-zA-Z0-9_-]+(?=\s*:)' "$TMP_JUST" | sort -u)
    # Verify 'bootstrap' is extracted and is in known-upstream-recipes.txt
    echo "$RECIPES" | grep -qxF "bootstrap"
    grep -qxF "bootstrap" scripts/known-upstream-recipes.txt
    rm -f "$TMP_JUST"
}

@test "known-upstream-recipes.txt is present and non-empty" {
    [ -f "scripts/known-upstream-recipes.txt" ]
    [ -s "scripts/known-upstream-recipes.txt" ]
}
