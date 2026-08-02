#!/usr/bin/bash
set -euo pipefail

copr_install_isolated() {
    local copr_name="$1"
    shift
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "ERROR: No packages specified for copr_install_isolated"
        return 1
    fi

    local repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

    echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

    # Retry loop — COPR infrastructure can be temporarily unavailable.
    # Pattern from Tailscale repo fetch at build_files/base/04-packages.sh:91.
    local retry=0 max_retries=3
    while [ $retry -lt $max_retries ]; do
        if dnf5 -y copr enable "$copr_name" && \
           dnf5 -y copr disable "$copr_name" && \
           dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"; then
            echo "Installed ${packages[*]} from $copr_name"
            return 0
        fi
        retry=$((retry + 1))
        if [ $retry -lt $max_retries ]; then
            echo "Retry $retry/$max_retries for COPR $copr_name..."
            sleep 10
        fi
    done
    echo "ERROR: Failed to install ${packages[*]} from COPR $copr_name after $max_retries attempts"
    return 1
}
