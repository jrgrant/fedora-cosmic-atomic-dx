#!/usr/bin/bash
# check-recipe-collisions.sh — Verify custom ujust recipes don't shadow upstream
#
# Extracts recipe names from 60-custom.just and diffs against a known list
# of upstream recipe names. Fails with exit code 1 if any collision is found.
# The known-upstream-recipes.txt list is maintained alongside this script
# and should be updated when ublue-os/main adds new ujust recipes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_JUST="$SCRIPT_DIR/../system_files/shared/usr/share/ublue-os/just/60-custom.just"
KNOWN_UPSTREAM="$SCRIPT_DIR/known-upstream-recipes.txt"

if [[ ! -f "$CUSTOM_JUST" ]]; then
    echo "ERROR: Custom justfile not found at $CUSTOM_JUST"
    exit 1
fi

if [[ ! -f "$KNOWN_UPSTREAM" ]]; then
    echo "ERROR: Known upstream recipes not found at $KNOWN_UPSTREAM"
    exit 1
fi

# Extract recipe names from 60-custom.just (lines starting with a word followed by ':')
# Skip comments, blank lines, and lines starting with 'import' or 'set'
CUSTOM_RECIPES=$(grep -oP '^\s*\K[a-zA-Z0-9_-]+(?=\s*:)' "$CUSTOM_JUST" | sort -u)

# Read known upstream recipes (skip comments and blank lines)
UPSTREAM_RECIPES=$(grep -v '^#' "$KNOWN_UPSTREAM" | grep -v '^$' | sort -u)

COLLISIONS=0

echo "=== Checking ujust recipe collisions ==="
echo "Custom recipes ($CUSTOM_JUST):"
echo "$CUSTOM_RECIPES" | sed 's/^/  - /'
echo ""

while IFS= read -r recipe; do
    if echo "$UPSTREAM_RECIPES" | grep -qxF "$recipe"; then
        echo "COLLISION: '$recipe' shadows upstream recipe"
        COLLISIONS=$((COLLISIONS + 1))
    fi
done <<< "$CUSTOM_RECIPES"

echo ""
if [[ $COLLISIONS -gt 0 ]]; then
    echo "FAILED: $COLLISIONS recipe name collision(s) found"
    echo "Rename custom recipes to avoid shadowing upstream ujust recipes."
    echo "Upstream recipes list: $KNOWN_UPSTREAM"
    exit 1
fi

echo "PASSED: No collisions"
