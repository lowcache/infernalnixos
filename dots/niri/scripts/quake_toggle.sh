#!/usr/bin/env bash
# Quake terminal toggle for niri (port of the Hyprland quake_toggle.sh).
# Strategy per state.md §5: a kitty instance with app-id "quake" parked on a
# dedicated "quake" stash workspace; toggle = move it to the focused workspace
# (floating, revealed) or back to the stash. Verb-swap of hyprctl -> niri msg.
#
# INERT until symlinked (Phase 1). Requires: niri, kitty, jq.
set -euo pipefail
LOG="/tmp/quake_toggle_niri.log"
exec 2>>"$LOG"; echo "--- $(date) $* ---" >>"$LOG"

APPID="quake"
STASH="quake"   # named stash workspace

win_json() { niri msg --json windows; }

# Find the quake window (by app-id). Empty if not running.
QUAKE=$(win_json | jq -c ".[] | select(.app_id == \"$APPID\")" 2>/dev/null | head -n1)

if [ -z "$QUAKE" ]; then
    echo "quake not running, launching floating" >>"$LOG"
    niri msg action spawn -- kitty --single-instance --app-id "$APPID"
    # The window-rule (open-floating) in config.kdl floats it on the focused ws.
    exit 0
fi

WIN_ID=$(printf '%s' "$QUAKE" | jq -r '.id')
WIN_WS=$(printf '%s' "$QUAKE" | jq -r '.workspace_id')
IS_FOCUSED=$(printf '%s' "$QUAKE" | jq -r '.is_focused')

# Current focused workspace id.
CUR_WS=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .id')

if [ "$WIN_WS" = "$CUR_WS" ] && [ "$IS_FOCUSED" = "true" ]; then
    # Visible and focused -> stash it away.
    echo "stashing quake (id=$WIN_ID) to $STASH" >>"$LOG"
    niri msg action move-window-to-workspace --window-id "$WIN_ID" "$STASH" || \
        niri msg action move-window-to-workspace "$STASH"
else
    # Hidden or unfocused -> bring to current workspace, float, focus.
    echo "revealing quake (id=$WIN_ID)" >>"$LOG"
    niri msg action move-window-to-workspace --window-id "$WIN_ID" "$CUR_WS" 2>/dev/null || true
    niri msg action focus-window --id "$WIN_ID" 2>/dev/null || true
fi
