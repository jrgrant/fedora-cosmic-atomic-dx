# fedora-cosmic-atomic-dx — ujust recipes (system-wide)

# Run after rebasing to a new image
[bootstrap]
bootstrap:
    #!/usr/bin/bash
    echo "==> fedora-cosmic-atomic-dx bootstrap"
    echo ""

    # Brew taps and key packages
    echo "--- Homebrew ---"
    brew tap ublue-os/tap 2>/dev/null || true
    brew list --formula starship &>/dev/null || brew install starship
    brew list --formula atuin &>/dev/null || brew install atuin
    brew list --formula eza &>/dev/null || brew install eza
    brew list --formula bat &>/dev/null || brew install bat
    brew list --formula fd &>/dev/null || brew install fd
    brew list --formula ripgrep &>/dev/null || brew install ripgrep
    brew list --formula zoxide &>/dev/null || brew install zoxide
    brew list --formula fzf &>/dev/null || brew install fzf

    # Starship prompt
    if ! grep -q "starship init" ~/.bashrc 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
        echo "  [add] starship to .bashrc"
    fi

    # Distrobox dev container
    if ! distrobox list 2>/dev/null | grep -q atomic-dev; then
        echo "--- Distrobox ---"
        distrobox create --name atomic-dev --image fedora:44 --yes
        distrobox enter atomic-dev -- bash -c "
            sudo dnf install -y gcc gcc-c++ make cmake git python3 nodejs ripgrep
        "
    fi

    echo ""
    echo "==> Bootstrap complete"

# Print system info
[info]
info:
    #!/usr/bin/bash
    echo "Image: $(rpm-ostree status --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); [print(d.get('origin','')) for d in d.get('deployments',[]) if d.get('booted')]" 2>/dev/null || echo unknown)"
    echo "Kernel: $(uname -r)"
    echo "Podman: $(podman --version 2>/dev/null || echo 'not found')"
    echo "Docker: $(docker --version 2>/dev/null || echo 'not found')"
    echo "VS Code: $(/opt/vscode/bin/code --version 2>/dev/null | head -1 || echo 'not found')"
    echo "Chrome: $(/opt/google/chrome/google-chrome --version 2>/dev/null || echo 'not found')"
    echo "Brave: $(/opt/brave.com/brave/brave --version 2>/dev/null || echo 'not found')"

# Update all self-updating apps
[update]
update:
    #!/usr/bin/bash
    echo "==> Updating brew packages..."
    brew update && brew upgrade
    echo "==> Updating flatpak..."
    flatpak update -y 2>/dev/null || true
    echo "==> Self-updating apps check..."
    echo "  VS Code: auto-updates on launch"
    echo "  Chrome: auto-updates via Google updater"
    echo "  Brave: auto-updates via Brave updater"

# Rollback to previous deployment
[rollback]
rollback:
    sudo rpm-ostree rollback
    @echo "==> Reboot to apply: sudo systemctl reboot"
