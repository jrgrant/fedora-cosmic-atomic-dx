# fedora-cosmic-atomic-dx — ujust recipes (system-wide)

# Run after rebasing to a new image
fca-bootstrap:
    #!/usr/bin/bash
    echo "==> fedora-cosmic-atomic-dx bootstrap"
    echo ""

    # Ensure WAYLAND_DISPLAY is in D-Bus activation env (cosmic-session#96)
    systemctl --user enable --now cosmic-keyring-env.service 2>/dev/null || true
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY 2>/dev/null || true

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

    # ---- User apps ----
    echo "--- User apps ---"
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    if ! flatpak remotes 2>/dev/null | grep -q flathub; then
        echo "  [warn] Flathub remote not available — skipping Flatpak app installs"
    else

    # Google Chrome
    if ! flatpak list 2>/dev/null | grep -q com.google.Chrome; then
        echo "  [install] google-chrome (flatpak)"
        if flatpak install -y flathub com.google.Chrome 2>&1; then
            echo "  [ok] google-chrome installed"
        else
            echo "  [FAIL] google-chrome install failed"
        fi
    else
        echo "  [skip] google-chrome already installed"
    fi

    # Brave Browser
    if ! flatpak list 2>/dev/null | grep -q com.brave.Browser; then
        echo "  [install] brave-browser (flatpak)"
        if flatpak install -y flathub com.brave.Browser 2>&1; then
            echo "  [ok] brave-browser installed"
        else
            echo "  [FAIL] brave-browser install failed"
        fi
    else
        echo "  [skip] brave-browser already installed"
    fi

    fi  # end Flathub remote check

    # VS Code — brew cask (proper desktop integration, no sandbox limitations)
    if ! brew list --cask visual-studio-code-linux &>/dev/null; then
        echo "  [install] vscode (brew cask)"
        if brew install --cask visual-studio-code-linux; then
            echo "  [ok] vscode installed"
        else
            echo "  [FAIL] vscode install failed"
        fi
    else
        echo "  [skip] vscode already installed"
    fi

    echo ""
    echo "==> Bootstrap complete"
    echo ""
    echo "Apps installed via Flatpak — updates handled by flatpak update"
    echo "Run 'ujust rebase-helper' to update brew + flatpak packages"

# Print system info
fca-info:
    #!/usr/bin/bash
    echo "Image: $(rpm-ostree status --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); [print(d.get('origin','')) for d in d.get('deployments',[]) if d.get('booted')]" 2>/dev/null || echo unknown)"
    echo "Kernel: $(uname -r)"
    echo "Podman: $(podman --version 2>/dev/null || echo 'not found')"
    echo "Docker: $(docker --version 2>/dev/null || echo 'not found')"
    echo "VS Code: $(code --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "Chrome: $(flatpak run com.google.Chrome --version 2>/dev/null || echo 'not installed')"
    echo "Brave: $(flatpak run com.brave.Browser --version 2>/dev/null || echo 'not installed')"

# Refresh user-level packages after a rebase
rebase-helper:
    #!/usr/bin/bash
    echo "==> Updating brew packages..."
    brew update && brew upgrade
    echo "==> Updating flatpak..."
    flatpak update -y
    echo "==> Updating brew casks..."
    brew upgrade --cask 2>/dev/null || true
    echo "==> Self-updating apps check..."
    echo "  VS Code: auto-updates via brew upgrade --cask"
    echo "  Chrome: updated via flatpak update (above)"
    echo "  Brave: updated via flatpak update (above)"

# Rollback to previous deployment
fca-rollback:
    sudo rpm-ostree rollback
    @echo "==> Reboot to apply: sudo systemctl reboot"
