#!/usr/bin/env bash
# Touchpad enable/disable toggle for niri (ASUS F10 / XF86TouchpadToggle).
# niri has no runtime input IPC, so this flips the `off` line in the touchpad
# block of config.kdl and reloads. Default (committed) state = enabled.
# Replaces the Hyprland hyprctl-based dots/hypr/.../toggle-touchpad.sh.
set -euo pipefail
CFG="$HOME/.config/niri/config.kdl"
M="@tptoggle@"

if grep -qE "^[[:space:]]*off // $M" "$CFG"; then
    # Currently disabled -> re-enable (comment the off line).
    sed -i "s|^\([[:space:]]*\)off // $M|\1// off // $M|" "$CFG"
    STATE="Enabled"
else
    # Currently enabled -> disable (uncomment the off line).
    sed -i "s|^\([[:space:]]*\)// off // $M|\1off // $M|" "$CFG"
    STATE="Disabled"
fi

if niri validate -c "$CFG" >/dev/null 2>&1; then
    niri msg action load-config-file
    notify-send -i input-touchpad-symbolic "Touchpad" "$STATE" 2>/dev/null || true
else
    notify-send -i dialog-error "Touchpad toggle" "config invalid; not reloaded" 2>/dev/null || true
    exit 1
fi
