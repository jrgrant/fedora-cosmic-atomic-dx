#!/usr/bin/env bash
# pin-current.sh — Capture current deployment state before a risky rebase
#
# Run before rebasing to a new image. Records enough state to roll back.
# Everything is written as your user — no root-owned files in the backup.
#
# Usage: bash scripts/pin-current.sh

set -euo pipefail

STATE_DIR="$HOME/.atomic-cosmic"
STATE_FILE="$STATE_DIR/pre-switch-state.txt"
BACKUP_DIR="$STATE_DIR/backup-$(date +%Y%m%d-%H%M%S)"
TMPFILE=$(mktemp)

# Ensure everything is user-owned from the start
mkdir -p "$STATE_DIR" "$BACKUP_DIR"

echo "==> Capturing current deployment state"
echo "    State file: $STATE_FILE"
echo "    Backup dir: $BACKUP_DIR"
echo ""

# ---- Deployment status (no root needed for rpm-ostree status) ----
{
    echo "--- Deployment status ---"
    echo "Date: $(date -Iseconds)"
    echo ""
} > "$STATE_FILE"

CURRENT_IMAGE="unknown"

if command -v rpm-ostree &>/dev/null; then
    echo "### rpm-ostree status" >> "$STATE_FILE"
    rpm-ostree status 2>&1 | tee -a "$STATE_FILE" || true

    CURRENT_IMAGE=$(rpm-ostree status --json 2>/dev/null | python3 -c "
import json, sys
def get_origin():
    d = json.load(sys.stdin)
    for dep in d.get('deployments', []):
        if dep.get('booted'):
            return dep.get('origin', '') or 'unknown'
    return 'unknown'
print(get_origin())
" 2>/dev/null || echo "unknown")

elif command -v bootc &>/dev/null; then
    echo "### bootc status" >> "$STATE_FILE"
    sudo bootc status > "$TMPFILE" 2>&1 || true
    cat "$TMPFILE" >> "$STATE_FILE"

    CURRENT_IMAGE=$(sudo bootc status --json 2>/dev/null | python3 -c "
import json, sys
def get_image():
    d = json.load(sys.stdin)
    booted = d.get('status', {}).get('booted', {})
    return booted.get('image', {}).get('image', '') or 'unknown'
print(get_image())
" 2>/dev/null || echo "unknown")

fi

echo "" >> "$STATE_FILE"
echo "Current image: $CURRENT_IMAGE" >> "$STATE_FILE"
echo "    Current origin: $CURRENT_IMAGE"

# ---- Layered packages ----
if command -v rpm-ostree &>/dev/null; then
    echo "" >> "$STATE_FILE"
    echo "### Layered packages" >> "$STATE_FILE"
    rpm-ostree status --json 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
for dep in d.get('deployments', []):
    if dep.get('booted'):
        for pkg in dep.get('requested-packages', []):
            print(pkg)
        break
" >> "$STATE_FILE" 2>/dev/null || true
fi

# ---- Backup /etc configs (use sudo to read, then chown to user) ----
echo ""
echo "--- Backing up /etc configs ---"

configs_to_backup=(
    /etc/fstab
    /etc/default/grub
    /etc/systemd/journald.conf
    /etc/containers/registries.conf
)

for cfg in "${configs_to_backup[@]}"; do
    if [ -r "$cfg" ]; then
        echo "  [backup] $cfg"
        cp "$cfg" "$BACKUP_DIR/"
    elif sudo test -r "$cfg" 2>/dev/null; then
        echo "  [backup] $cfg (via sudo)"
        sudo cp "$cfg" "$BACKUP_DIR/"
        sudo chown "$(id -u):$(id -g)" "$BACKUP_DIR/$(basename "$cfg")"
    fi
done

# Flatpak remotes — readable without root
if [ -d /etc/flatpak/remotes.d ]; then
    echo "  [backup] /etc/flatpak/remotes.d/"
    cp -rL /etc/flatpak/remotes.d "$BACKUP_DIR/" 2>/dev/null || true
fi

# Copy state file into backup
cp "$STATE_FILE" "$BACKUP_DIR/"
rm -f "$TMPFILE"

echo ""
echo "============================================"
echo "  State captured. Everything owned by $(whoami)."
echo ""
echo "  To roll back after a bad rebase:"
echo ""
if [ "$CURRENT_IMAGE" != "unknown" ]; then
    echo "    sudo rpm-ostree rebase '$CURRENT_IMAGE'"
else
    echo "    sudo rpm-ostree rollback"
fi
echo ""
echo "  State file: $STATE_FILE"
echo "  Backup dir: $BACKUP_DIR"
echo "============================================"
