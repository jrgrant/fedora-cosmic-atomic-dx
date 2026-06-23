#!/usr/bin/env bash
# bootstrap.sh — Post-install user-level setup for atomic-cosmic
#
# Run once after `bootc switch` to the atomic-cosmic image.
# Idempotent — safe to re-run. Each step checks whether it's
# already been done before repeating work.
#
# Usage: bash scripts/bootstrap.sh

set -euo pipefail

echo "==> atomic-cosmic bootstrap"
echo ""

# ---- Homebrew taps ----
echo "--- Homebrew taps ---"
brew_taps=(
    ublue-os/tap
)

for tap in "${brew_taps[@]}"; do
    if brew tap | grep -q "$tap"; then
        echo "  [skip] brew tap $tap (already added)"
    else
        echo "  [add] brew tap $tap"
        brew tap "$tap"
    fi
done

# Install key brew packages
brew_packages=(
    starship
    atuin
    eza
    bat
    fd
    ripgrep
    zoxide
    fzf
)

for pkg in "${brew_packages[@]}"; do
    if brew list --formula "$pkg" &>/dev/null; then
        echo "  [skip] brew install $pkg (already installed)"
    else
        echo "  [install] brew install $pkg"
        brew install "$pkg"
    fi
done

echo ""
# ---- Browsers (native RPMs — no Flatpak sandbox) ----
echo "--- Browsers ---"
echo "  google-chrome-stable: in image (native RPM from Google repo)"
echo "  firefox: in image (native RPM from Fedora)"
echo "  brave-browser: brew cask is macOS-only — install via RPM if needed"

echo ""
# ---- Justfiles ----
echo "--- Just recipes ---"
echo "  [skip] Use 'ujust' — Bluefin recipes are built into the image"
echo "  Run 'ujust --list' to see available commands"

echo ""

# ---- Shell integration ----
echo "--- Shell integration ---"

# Starship prompt for bash
BASHRC="$HOME/.bashrc"
STARSHIP_INIT='eval "$(starship init bash)"'

if [ -f "$BASHRC" ] && grep -q "starship init" "$BASHRC"; then
    echo "  [skip] starship already in .bashrc"
else
    echo "  [add] starship init to .bashrc"
    echo "" >> "$BASHRC"
    echo "# atomic-cosmic: starship prompt" >> "$BASHRC"
    echo "$STARSHIP_INIT" >> "$BASHRC"
fi

# Starship prompt for fish
FISH_CONFIG="$HOME/.config/fish/config.fish"
STARSHIP_FISH_INIT='starship init fish | source'

if [ -f "$FISH_CONFIG" ] && grep -q "starship init" "$FISH_CONFIG"; then
    echo "  [skip] starship already in config.fish"
elif command -v fish &>/dev/null; then
    echo "  [add] starship init to config.fish"
    mkdir -p "$(dirname "$FISH_CONFIG")"
    echo "# atomic-cosmic: starship prompt" >> "$FISH_CONFIG"
    echo "$STARSHIP_FISH_INIT" >> "$FISH_CONFIG"
fi

# fzf keybindings
if [ -f "$BASHRC" ] && grep -q "fzf/shell/key-bindings" "$BASHRC"; then
    echo "  [skip] fzf already in .bashrc"
else
    echo "  [add] fzf keybindings to .bashrc"
    echo "# atomic-cosmic: fzf keybindings" >> "$BASHRC"
    echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> "$BASHRC"
fi

echo ""

# ---- Distrobox dev container ----
echo "--- Distrobox ---"
DEVBOX_NAME="atomic-dev"

if distrobox list 2>/dev/null | grep -q "$DEVBOX_NAME"; then
    echo "  [skip] distrobox $DEVBOX_NAME already exists"
else
    echo "  [create] distrobox $DEVBOX_NAME (fedora:44)"
    distrobox create --name "$DEVBOX_NAME" --image fedora:44 --yes
    echo "  [setup] distrobox $DEVBOX_NAME — install dev tools"
    distrobox enter "$DEVBOX_NAME" -- bash -c "
        sudo dnf install -y \
            gcc gcc-c++ make cmake git \
            python3 python3-pip python3-devel \
            nodejs npm \
            ripgrep fd-find bat \
        && echo 'distrobox $DEVBOX_NAME ready'
    "
fi

echo ""

# ---- Finish ----
echo "==> Bootstrap complete"
echo ""
echo "Next steps:"
echo "  just --list              # available recipes"
echo "  distrobox enter $DEVBOX_NAME   # enter dev container"
echo ""
echo "Re-run anytime — all steps are idempotent."
