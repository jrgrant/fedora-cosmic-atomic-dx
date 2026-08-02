#!/usr/bin/bash
# 20-cosmic-keyring-fix.sh — Fix gnome-keyring for COSMIC desktop
#
# Two fixes needed:
# 1. xdg-autostart: OnlyShowIn excludes COSMIC (cosmic-session#141, cosmic-epoch#3453)
# 2. xdg-desktop-portal: UseIn=gnome blocks Chrome/Electron from accessing
#    org.freedesktop.secrets via the portal Secret API (cosmic-epoch#3626)
#
# Without fix 2, Chrome with --password-store=gnome-libsecret silently falls
# back to basic mode because the portal refuses to activate for COSMIC.

set -eoux pipefail

# Fix 1: Autostart files
for f in /etc/xdg/autostart/gnome-keyring-{secrets,pkcs11,ssh}.desktop; do
    if [ -f "$f" ]; then
        sed -i 's/OnlyShowIn=GNOME;Unity;MATE;/OnlyShowIn=GNOME;Unity;MATE;COSMIC;/' "$f"
        echo "Fixed: $f"
    fi
done

# Fix 2: Portal — add COSMIC to UseIn (only if not already there from system_files overlay)
PORTAL_FILE=/usr/share/xdg-desktop-portal/portals/gnome-keyring.portal
if [ -f "$PORTAL_FILE" ]; then
    if ! grep -q "COSMIC" "$PORTAL_FILE"; then
        sed -i 's/UseIn=gnome/UseIn=gnome;COSMIC/' "$PORTAL_FILE"
        echo "Fixed: $PORTAL_FILE"
    else
        echo "Already fixed: $PORTAL_FILE"
    fi
fi
