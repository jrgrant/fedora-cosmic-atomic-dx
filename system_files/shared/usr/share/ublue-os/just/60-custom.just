# fedora-cosmic-atomic-dx — ujust recipes (system-wide)

# Run after rebasing to a new image
bootstrap:
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

    # ---- User apps (~/.opt, self-updating) ----
    echo "--- User apps ---"
    mkdir -p ~/.opt ~/.local/bin ~/.local/share/applications ~/.local/share/icons

    # Ensure ~/.local/bin is first in PATH (beats brew's code, etc.)
    if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo "  [add] ~/.local/bin to PATH in .bashrc"
    fi

    # Google Chrome — binary
    if [ ! -f ~/.opt/google/chrome/google-chrome ]; then
        echo "  [install] google-chrome to ~/.opt"
        curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" -o /tmp/chrome.rpm
        mkdir -p /tmp/chrome-extract && rpm2cpio /tmp/chrome.rpm | (cd /tmp/chrome-extract && cpio -idm 2>/dev/null)
        cp -r /tmp/chrome-extract/opt/* ~/.opt/
        rm -rf /tmp/chrome.rpm /tmp/chrome-extract
        ln -sf ~/.opt/google/chrome/google-chrome ~/.local/bin/google-chrome
        # Remove stale First Run sentinel (breaks session persistence on COSMIC)
        rm -f ~/.config/google-chrome/First\ Run
    else
        echo "  [skip] google-chrome already in ~/.opt"
    fi
    # Google Chrome — desktop + icons (separate guard)
    if [ ! -f ~/.local/share/applications/google-chrome.desktop ]; then
        echo "  [add] chrome desktop shortcut + icons"
        curl -fsSL "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" -o /tmp/chrome.rpm
        mkdir -p /tmp/chrome-extract && rpm2cpio /tmp/chrome.rpm | (cd /tmp/chrome-extract && cpio -idm 2>/dev/null)
        sed "s|Exec=/usr/bin/google-chrome-stable|Exec=$HOME/.opt/google/chrome/google-chrome --password-store=basic --no-first-run|g" \
            /tmp/chrome-extract/usr/share/applications/google-chrome.desktop \
            > ~/.local/share/applications/google-chrome.desktop
        # Install icons from app bundle (RPM doesn't ship them)
        for png in ~/.opt/google/chrome/product_logo_*.png; do
            sz=$(basename "$png" | sed 's/product_logo_//; s/.png//')
            mkdir -p ~/.local/share/icons/hicolor/${sz}x${sz}/apps
            cp "$png" ~/.local/share/icons/hicolor/${sz}x${sz}/apps/google-chrome.png
        done
        rm -rf /tmp/chrome.rpm /tmp/chrome-extract
    fi

    # Brave Browser — binary
    if [ ! -f ~/.opt/brave.com/brave/brave ]; then
        echo "  [install] brave-browser to ~/.opt"
        BRAVE_VER=$(curl -fsSL "https://api.github.com/repos/brave/brave-browser/releases/latest" | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
        curl -fsSL "https://github.com/brave/brave-browser/releases/download/v${BRAVE_VER}/brave-browser-${BRAVE_VER}-1.x86_64.rpm" -o /tmp/brave.rpm
        mkdir -p /tmp/brave-extract && rpm2cpio /tmp/brave.rpm | (cd /tmp/brave-extract && cpio -idm 2>/dev/null)
        cp -r /tmp/brave-extract/opt/* ~/.opt/
        rm -rf /tmp/brave.rpm /tmp/brave-extract
        ln -sf ~/.opt/brave.com/brave/brave ~/.local/bin/brave-browser
        # Remove stale First Run sentinel (breaks session persistence on COSMIC)
        rm -f ~/.config/BraveSoftware/Brave-Browser/First\ Run
    else
        echo "  [skip] brave-browser already in ~/.opt"
    fi
    # Brave Browser — desktop + icons (separate guard)
    if [ ! -f ~/.local/share/applications/brave-browser.desktop ]; then
        echo "  [add] brave desktop shortcut + icons"
        BRAVE_VER=$(curl -fsSL "https://api.github.com/repos/brave/brave-browser/releases/latest" | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
        curl -fsSL "https://github.com/brave/brave-browser/releases/download/v${BRAVE_VER}/brave-browser-${BRAVE_VER}-1.x86_64.rpm" -o /tmp/brave.rpm
        mkdir -p /tmp/brave-extract && rpm2cpio /tmp/brave.rpm | (cd /tmp/brave-extract && cpio -idm 2>/dev/null)
        sed "s|Exec=/usr/bin/brave-browser-stable|Exec=$HOME/.opt/brave.com/brave/brave --password-store=basic --no-first-run|g" \
            /tmp/brave-extract/usr/share/applications/brave-browser.desktop \
            > ~/.local/share/applications/brave-browser.desktop
        # Install icons from app bundle (RPM doesn't ship them)
        for png in ~/.opt/brave.com/brave/product_logo_*.png; do
            sz=$(basename "$png" | sed 's/product_logo_//; s/.png//')
            mkdir -p ~/.local/share/icons/hicolor/${sz}x${sz}/apps
            cp "$png" ~/.local/share/icons/hicolor/${sz}x${sz}/apps/brave-browser.png
        done
        rm -rf /tmp/brave.rpm /tmp/brave-extract
    fi

    # VS Code — binary
    if [ ! -f ~/.opt/VSCode-linux-x64/bin/code ]; then
        echo "  [install] vscode to ~/.opt"
        VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
        curl -fsSL "$VSCODE_URL" -o /tmp/vscode.tar.gz
        tar -xzf /tmp/vscode.tar.gz -C ~/.opt
        rm -f /tmp/vscode.tar.gz
        ln -sf ~/.opt/VSCode-linux-x64/bin/code ~/.local/bin/code
    else
        echo "  [skip] vscode already in ~/.opt"
    fi
    # VS Code — desktop shortcut (separate guard)
    if [ ! -f ~/.local/share/applications/code.desktop ]; then
        printf '[Desktop Entry]\nName=Visual Studio Code\nComment=Code Editing. Redefined\nGenericName=Text Editor\nExec=%s --no-sandbox %%F\nIcon=%s/resources/app/resources/linux/code.png\nType=Application\nCategories=Development;IDE;\nMimeType=text/plain;inode/directory;\n' \
            "$HOME/.opt/VSCode-linux-x64/bin/code" \
            "$HOME/.opt/VSCode-linux-x64" \
            > ~/.local/share/applications/code.desktop
        echo "  [add] vscode desktop shortcut"
    fi

    # Clean up brew's VS Code cask if present (ours takes priority)
    if brew list --cask visual-studio-code-linux &>/dev/null; then
        echo "  [cleanup] removing brew VS Code cask"
        brew uninstall --cask visual-studio-code-linux 2>/dev/null || true
    fi

    # Refresh icon cache and desktop database
    gtk-update-icon-cache ~/.local/share/icons/hicolor 2>/dev/null || true
    update-desktop-database ~/.local/share/applications 2>/dev/null || true

    echo ""
    echo "==> Bootstrap complete"
    echo ""
    echo "CRITICAL: VS Code needs password-store set for COSMIC keyring:"
    echo "  Add '\"password-store\": \"gnome\"' to ~/.config/Code/User/settings.json"

# Print system info
info:
    #!/usr/bin/bash
    echo "Image: $(rpm-ostree status --json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); [print(d.get('origin','')) for d in d.get('deployments',[]) if d.get('booted')]" 2>/dev/null || echo unknown)"
    echo "Kernel: $(uname -r)"
    echo "Podman: $(podman --version 2>/dev/null || echo 'not found')"
    echo "Docker: $(docker --version 2>/dev/null || echo 'not found')"
    echo "VS Code: $(~/.local/bin/code --version 2>/dev/null | head -1 || echo 'not installed')"
    echo "Chrome: $(~/.local/bin/google-chrome --version 2>/dev/null || echo 'not installed')"
    echo "Brave: $(~/.local/bin/brave-browser --version 2>/dev/null || echo 'not installed')"

# Refresh user-level packages after a rebase
rebase-helper:
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
rollback:
    sudo rpm-ostree rollback
    @echo "==> Reboot to apply: sudo systemctl reboot"
