#!/usr/bin/env bash

# Touchpad Device Name from `hyprctl devices`
DEVICE="asup1205:00-093a:2008-touchpad"
STATE_FILE="$HOME/.cache/touchpad_state"

# Create state file if it doesn't exist (default to true / enabled)
if [ ! -f "$STATE_FILE" ]; then
    echo "true" > "$STATE_FILE"
fi

CURRENT_STATE=$(cat "$STATE_FILE")

# Log execution for debugging purposes
echo "$(date): Touchpad toggle triggered. Current state was: $CURRENT_STATE" >> /tmp/touchpad.log

if [ "$CURRENT_STATE" = "true" ]; then
    # Disable touchpad
    hyprctl keyword "device[$DEVICE]:enabled" false
    echo "false" > "$STATE_FILE"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i input-touchpad-symbolic "Touchpad" "Touchpad Disabled"
    fi
else
    # Enable touchpad
    hyprctl keyword "device[$DEVICE]:enabled" true
    echo "true" > "$STATE_FILE"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i input-touchpad-symbolic "Touchpad" "Touchpad Enabled"
    fi
fi
