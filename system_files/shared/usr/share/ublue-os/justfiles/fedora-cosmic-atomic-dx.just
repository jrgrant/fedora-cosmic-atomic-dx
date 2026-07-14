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

    # ---- Browsers (user apps, ~/.opt, self-updating) ----
    echo "--- Browsers ---"
    mkdir -p ~/.opt ~/.local/bin

    # Google Chrome
    if [ ! -f ~/.opt/opt/google/chrome/google-chrome ]; then
        echo "  [install] google-chrome to ~/.opt"
        curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" -o /tmp/chrome.rpm
        rpm2cpio /tmp/chrome.rpm | (cd ~/.opt && cpio -idmv)
        rm -f /tmp/chrome.rpm
        ln -sf ~/.opt/opt/google/chrome/google-chrome ~/.local/bin/google-chrome
    else
        echo "  [skip] google-chrome already in ~/.opt"
    fi

    # Brave Browser
    if [ ! -f ~/.opt/opt/brave.com/brave/brave ]; then
        echo "  [install] brave-browser to ~/.opt"
        curl -fsSL "https://github.com/brave/brave-browser/releases/latest/download/brave-browser-x86_64.rpm" -o /tmp/brave.rpm
        rpm2cpio /tmp/brave.rpm | (cd ~/.opt && cpio -idmv)
        rm -f /tmp/brave.rpm
        ln -sf ~/.opt/opt/brave.com/brave/brave ~/.local/bin/brave-browser
    else
        echo "  [skip] brave-browser already in ~/.opt"
    fi

    # VS Code
    if [ ! -f ~/.opt/VSCode-linux-x64/bin/code ]; then
        echo "  [install] vscode to ~/.opt"
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
        curl -fsSL "$VSCODE_URL" -o /tmp/vscode.tar.gz
        mkdir -p ~/.opt
        tar -xzf /tmp/vscode.tar.gz -C ~/.opt
        rm -f /tmp/vscode.tar.gz
        ln -sf ~/.opt/VSCode-linux-x64/bin/code ~/.local/bin/code
    else
        echo "  [skip] vscode already in ~/.opt"
    fi

    echo ""
    echo "==> Bootstrap complete"
    echo ""
    echo "Post-rebase cleanup (optional):"
    echo "  brew uninstall --cask visual-studio-code-linux 2>/dev/null"
    echo "  flatpak uninstall com.google.Chrome 2>/dev/null"
    echo "  flatpak uninstall com.brave.Browser 2>/dev/null"
    echo ""
    echo "Verify secrets persistence:"
    echo "  Log into Chrome, reboot, check session survives"

# Print system info
[info]
info:
    #!/usr/bin/bash
    echo "Image: $(rpm-ostree status --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); [print(d.get('origin','')) for d in d.get('deployments',[]) if d.get('booted')]" 2>/dev/null || echo unknown)"
    echo "Kernel: $(uname -r)"
    echo "Podman: $(podman --version 2>/dev/null || echo 'not found')"
    echo "Docker: $(docker --version 2>/dev/null || echo 'not found')"
    echo "VS Code: $(~/.local/bin/code --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "Chrome: $(~/.local/bin/google-chrome --version 2>/dev/null || echo 'not installed')"
    echo "Brave: $(~/.local/bin/brave-browser --version 2>/dev/null || echo 'not installed')"

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
