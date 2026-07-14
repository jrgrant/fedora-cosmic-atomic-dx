# fedora-cosmic-atomic-dx — ensure /usr/local/bin takes priority
# over Homebrew paths for system-installed apps
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
    export PATH="/usr/local/bin:$PATH"
fi
