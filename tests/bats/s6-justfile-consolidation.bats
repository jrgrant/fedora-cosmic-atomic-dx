#!/usr/bin/env bats
# S6: Justfile consolidation and browser install mechanism
#
# Covers spec: docs/superpowers/specs/2026-08-02-upstream-dependency-catalog-recommendations.md
#
# Structural tests — grep, file-existence, content assertions.  No runtime
# code, no compiled language.  Every test is expected to fail (RED) before
# implementation.
#
# Test groups:
#   T1-T2:   Dead justfile removed and archived              (FR-S6-1 / Scenario 1)
#   T3-T5:   Apps installed via correct mechanism            (FR-S6-2,3,4 / Scenario 2,3)
#   T6:      No ~/.opt / rpm2cpio / cpio in active justfile (FR-S6-6 / Scenario 4)
#   T7-T9:   COSMIC keyring fix structural verification      (FR-S6-7,8 / Scenario 5)
#   T10-T11: fca-info Flatpak version query with fallback     (FR-S6-9 / Scenario 6)
#   T12:     rebase-helper runs flatpak update               (FR-S6-10 / Scenario 7)
#   T13-T14: Bootstrap logs per-app success/failure          (Scenario 8)
#   T15:     Flathub remote verified before installs         (Scenario 9)
#   T16:     cosmic-keyring-env.service + dbus activation    (Scenario 10)

setup() {
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
    ACTIVE_JUST="$PROJECT_ROOT/system_files/shared/usr/share/ublue-os/just/60-custom.just"
    DEAD_JUST="$PROJECT_ROOT/system_files/shared/usr/share/ublue-os/justfiles/fedora-cosmic-atomic-dx.just"
    KEYRING_FIX="$PROJECT_ROOT/build_files/base/20-cosmic-keyring-fix.sh"
    ARCHIVE_DIR="$PROJECT_ROOT/docs/archive"
}

# =============================================================================
# Scenario 1: Dead justfile removed and archived (FR-S6-1)
# =============================================================================

# T1: Dead justfile must not exist in its original location
@test "T1: dead justfile absent from justfiles/ directory" {
    [ ! -f "$DEAD_JUST" ]
}

# T2: Dead justfile must be archived under docs/archive/
@test "T2: dead justfile archived at docs/archive/fedora-cosmic-atomic-dx.just" {
    [ -f "$ARCHIVE_DIR/fedora-cosmic-atomic-dx.just" ]
}

# =============================================================================
# Scenario 2: Active justfile installs apps via correct mechanism (FR-S6-2,3,4)
# =============================================================================

# T3: Chrome installed via Flatpak with install-failure logging
@test "T3: Chrome installed via flatpak with error logging (no stderr suppression)" {
    # The flatpak install line for Chrome must not redirect stderr to /dev/null
    run grep 'flatpak install.*com\.google\.Chrome' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    # The matched line must NOT contain 2>/dev/null — failures must be visible
    ! grep 'flatpak install.*com\.google\.Chrome' "$ACTIVE_JUST" | grep -q '2>/dev/null'
}

# T4: Brave installed via Flatpak with install-failure logging
@test "T4: Brave installed via flatpak with error logging (no stderr suppression)" {
    run grep 'flatpak install.*com\.brave\.Browser' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    ! grep 'flatpak install.*com\.brave\.Browser' "$ACTIVE_JUST" | grep -q '2>/dev/null'
}

# T5: VS Code installed via brew cask (not Flatpak)
@test "T5: VS Code installed via brew cask, not flatpak" {
    # Must have a brew cask install for VS Code
    run grep -E 'brew install.*(--cask\s+)?visual-studio-code(-linux)?' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    # Must NOT have a flatpak install for VS Code
    run grep 'flatpak install.*com\.visualstudio\.code' "$ACTIVE_JUST"
    [ "$status" -ne 0 ]
}

# =============================================================================
# Scenario 3: No ~/.opt or rpm2cpio references in active justfile (FR-S6-6)
# =============================================================================

# T6: Active justfile has no ~/.opt, rpm2cpio, or cpio -idmv references
@test "T6: active justfile has no ~/.opt, rpm2cpio, or cpio -idmv references" {
    run grep -E '~/\.opt|rpm2cpio|cpio\s+-idmv' "$ACTIVE_JUST"
    [ "$status" -ne 0 ]
}

# =============================================================================
# Scenario 4: COSMIC keyring fix structural verification (FR-S6-7,8)
# =============================================================================

# T7: cosmic-keyring-fix.sh patches gnome-keyring.portal UseIn=COSMIC
@test "T7: cosmic-keyring-fix patches gnome-keyring.portal UseIn for COSMIC" {
    run grep -q "UseIn=gnome;COSMIC" "$KEYRING_FIX"
    [ "$status" -eq 0 ]
}

# T8: cosmic-keyring-fix.sh patches autostart OnlyShowIn for COSMIC
@test "T8: cosmic-keyring-fix patches autostart OnlyShowIn for COSMIC" {
    run grep -q "OnlyShowIn=GNOME;Unity;MATE;COSMIC" "$KEYRING_FIX"
    [ "$status" -eq 0 ]
}

# T9: cosmic-keyring-fix.sh applies fixes to all three keyring desktop files
@test "T9: cosmic-keyring-fix patches all three gnome-keyring autostart files" {
    # The for-loop uses brace expansion to cover secrets, pkcs11, ssh in one line
    run grep 'gnome-keyring-{secrets,pkcs11,ssh}' "$KEYRING_FIX"
    [ "$status" -eq 0 ]
    # And the sed inside the loop patches OnlyShowIn for COSMIC
    run grep 'OnlyShowIn=GNOME;Unity;MATE;COSMIC' "$KEYRING_FIX"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Scenario 5: fca-info queries app versions via Flatpak (FR-S6-9)
# =============================================================================

# T10: fca-info queries VS Code version via code CLI (brew cask)
@test "T10: fca-info queries VS Code version via code CLI" {
    run grep 'code --version' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
}

# T11: fca-info queries Chrome and Brave via flatpak with not-installed fallback
@test "T11: fca-info queries browser versions via flatpak with fallback" {
    run grep 'flatpak run com\.google\.Chrome --version' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    run grep 'flatpak run com\.brave\.Browser --version' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    # Each flatpak browser query must have a || echo 'not installed' fallback
    run grep -c "flatpak run.*--version.*||.*echo.*not installed" "$ACTIVE_JUST"
    [ "$output" -ge 2 ]
}

# =============================================================================
# Scenario 6: rebase-helper runs flatpak update (FR-S6-10)
# =============================================================================

# T12: rebase-helper executes flatpak update -y
@test "T12: rebase-helper runs flatpak update -y" {
    run grep 'flatpak update -y' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Scenario 7: Bootstrap logs success/failure for each app install
# =============================================================================

# T13: Bootstrap reports explicit [install] or [skip] for each app
@test "T13: bootstrap logs per-app install/skip for Chrome, Brave, and VS Code" {
    # Each app install block must have an explicit echo for install or skip
    local chrome_logs=$(grep -c 'echo.*\[\(install\|skip\)\].*[Cc]hrome' "$ACTIVE_JUST")
    local brave_logs=$(grep -c 'echo.*\[\(install\|skip\)\].*[Bb]rave' "$ACTIVE_JUST")
    local vscode_logs=$(grep -c 'echo.*\[\(install\|skip\)\].*[Vv][Ss]\?[Cc]ode' "$ACTIVE_JUST")
    [ "$chrome_logs" -ge 1 ]
    [ "$brave_logs" -ge 1 ]
    [ "$vscode_logs" -ge 1 ]
}

# T14: Bootstrap does not silently discard install errors with || true alone
@test "T14: flatpak install commands do not discard errors silently" {
    # flatpak install lines must not end with '|| true' without any error
    # handling or logging on failure
    run grep 'flatpak install' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    # Each flatpak install line must not have 2>/dev/null (errors must be visible)
    ! grep 'flatpak install' "$ACTIVE_JUST" | grep -q '2>/dev/null'
}

# =============================================================================
# Scenario 9: Flathub remote verified before app installs
# =============================================================================

# T15: fca-bootstrap ensures flathub remote is configured before installing apps
@test "T15: fca-bootstrap adds flathub remote before flatpak installs" {
    # The remote-add must appear before any flatpak install line
    run grep -n 'flatpak remote-add.*flathub' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    local remote_line=$(echo "$output" | head -1 | cut -d: -f1)

    run grep -n 'flatpak install' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
    local first_install_line=$(echo "$output" | head -1 | cut -d: -f1)

    # Remote setup must occur at an earlier line than first install
    [ "$remote_line" -lt "$first_install_line" ]
}

# =============================================================================
# Scenario 10: cosmic-keyring-env.service and dbus activation preserved
# =============================================================================

# T16: fca-bootstrap enables cosmic-keyring-env.service
@test "T16: fca-bootstrap enables cosmic-keyring-env.service" {
    run grep 'cosmic-keyring-env\.service' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
}

# T17: fca-bootstrap activates dbus environment for WAYLAND_DISPLAY
@test "T17: fca-bootstrap runs dbus-update-activation-environment for WAYLAND_DISPLAY" {
    run grep 'dbus-update-activation-environment.*WAYLAND_DISPLAY' "$ACTIVE_JUST"
    [ "$status" -eq 0 ]
}
