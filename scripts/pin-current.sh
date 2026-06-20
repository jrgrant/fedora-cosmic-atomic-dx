#!/usr/bin/env bash
# pin-current.sh — Capture current deployment state before a risky rebase
#
# Run before `bootc switch` to your custom image. This records
# enough state to roll back even if the new deployment won't boot.
#
# Output: prints the rollback command and saves state to
# ~/.atomic-cosmic/pre-switch-state.txt
#
# Usage: bash scripts/pin-current.sh

set -euo pipefail

STATE_DIR="$HOME/.atomic-cosmic"
STATE_FILE="$STATE_DIR/pre-switch-state.txt"
BACKUP_DIR="$STATE_DIR/backup-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$STATE_DIR" "$BACKUP_DIR"

echo "==> Capturing current deployment state"
echo "    State file: $STATE_FILE"
echo "    Backup dir: $BACKUP_DIR"
echo ""

# ---- bootc/rpm-ostree status ----
echo "--- Deployment status ---" > "$STATE_FILE"
echo "Date: $(date -Iseconds)" >> "$STATE_FILE"

if command -v bootc &>/dev/null; then
    echo "" >> "$STATE_FILE"
    echo "### bootc status" >> "$STATE_FILE"
    bootc status 2>&1 | tee -a "$STATE_FILE"

    # Capture the current booted image reference
    CURRENT_IMAGE=$(bootc status --json 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
try:
    booted = d.get('status', {}).get('booted', {})
    image = booted.get('image', {}).get('image', '') or booted.get('cached_update', {}).get('image', {}).get('image', '')
    if not image:
        image = 'unknown'
    print(image)
except: print('unknown')
" 2>/dev/null || echo "unknown")

    echo ""
    echo "    Current booted image: $CURRENT_IMAGE"

elif command -v rpm-ostree &>/dev/null; then
    echo "" >> "$STATE_FILE"
    echo "### rpm-ostree status" >> "$STATE_FILE"
    rpm-ostree status 2>&1 | tee -a "$STATE_FILE"

    CURRENT_IMAGE=$(rpm-ostree status --json 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
try:
    deployments = d.get('deployments', [])
    for dep in deployments:
        if dep.get('booted'):
            origin = dep.get('origin', '')
            print(origin)
            break
except: print('unknown')
" 2>/dev/null || echo "unknown")

    echo ""
    echo "    Current origin: $CURRENT_IMAGE"
else
    echo "    WARNING: neither bootc nor rpm-ostree found — can't capture deployment"
fi

# ---- Layered packages ----
echo "" >> "$STATE_FILE"
echo "### Layered packages" >> "$STATE_FILE"
if command -v rpm-ostree &>/dev/null; then
    rpm-ostree status --json 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
for dep in d.get('deployments', []):
    if dep.get('booted'):
        for pkg in dep.get('requested-packages', []):
            print(pkg)
        break
" | tee -a "$STATE_FILE"
fi

# ---- Backup key configs ----
echo ""
echo "--- Backing up key configs ---"

configs_to_backup=(
    /etc/fstab
    /etc/default/grub
    /etc/systemd/journald.conf
    /etc/containers/registries.conf
    /etc/flatpak/remotes.d/
)

for cfg in "${configs_to_backup[@]}"; do
    if [ -e "$cfg" ]; then
        echo "  [backup] $cfg"
        cp -rL "$cfg" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# Copy state file into backup
cp "$STATE_FILE" "$BACKUP_DIR/"

echo ""
echo "============================================"
echo "  State captured."
echo ""
echo "  To roll back after a bad rebase:"
echo ""
if [ "$CURRENT_IMAGE" != "unknown" ]; then
    echo "    bootc switch '$CURRENT_IMAGE'"
    echo ""
    echo "    # or for rpm-ostree systems:"
    echo "    # rpm-ostree rebase '$CURRENT_IMAGE'"
else
    echo "    bootc rollback"
    echo ""
    echo "    # or for rpm-ostree systems:"
    echo "    # rpm-ostree rollback"
fi
echo ""
echo "  State file: $STATE_FILE"
echo "  Backup dir: $BACKUP_DIR"
echo "============================================"
