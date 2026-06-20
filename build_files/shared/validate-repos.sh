#!/usr/bin/bash
# validate-repos.sh — Ensure all third-party repos are disabled before commit
# Copied from bluefin/build_files/shared/validate-repos.sh

echo "::group:: ===$(basename "$0")==="

set -eou pipefail

REPOS_DIR="/etc/yum.repos.d"
VALIDATION_FAILED=0
ENABLED_REPOS=()

echo "Validating all repository files are disabled..."

if [[ ! -d "$REPOS_DIR" ]]; then
    echo "Warning: $REPOS_DIR does not exist"
    exit 0
fi

check_repo_file() {
    local repo_file="$1"
    local basename_file
    basename_file=$(basename "$repo_file")
    [[ ! -f "$repo_file" ]] && return 0
    [[ ! -r "$repo_file" ]] && return 0
    if grep -q "^enabled=1" "$repo_file" 2>/dev/null; then
        echo "ENABLED: $basename_file"
        ENABLED_REPOS+=("$basename_file")
        VALIDATION_FAILED=1
        echo "   Enabled sections:"
        local section_name=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[.*\]$ ]]; then
                section_name="$line"
            elif [[ "$line" =~ ^enabled=1 ]]; then
                echo "     - $section_name"
            fi
        done < "$repo_file"
    else
        echo "Disabled: $basename_file"
    fi
}

for repo in "$REPOS_DIR"/_copr:copr.fedorainfracloud.org:*.repo; do
    [[ -f "$repo" ]] && check_repo_file "$repo"
done

for repo in "$REPOS_DIR"/_copr_*.repo; do
    [[ -f "$repo" ]] && check_repo_file "$repo"
done

OTHER_REPOS=(
    "negativo17-fedora-multimedia.repo"
    "tailscale.repo"
    "vscode.repo"
    "docker-ce.repo"
    "fedora-cisco-openh264.repo"
    "fedora-coreos-pool.repo"
)
for repo_name in "${OTHER_REPOS[@]}"; do
    repo_path="$REPOS_DIR/$repo_name"
    [[ -f "$repo_path" ]] && check_repo_file "$repo_path"
done

for repo in "$REPOS_DIR"/rpmfusion-*.repo; do
    [[ -f "$repo" ]] && check_repo_file "$repo"
done

if [[ $VALIDATION_FAILED -eq 1 ]]; then
    echo "VALIDATION FAILED"
    for repo in "${ENABLED_REPOS[@]}"; do
        echo "  • $repo"
    done
    exit 1
fi

echo "All repos disabled — OK"
echo "::endgroup::"
