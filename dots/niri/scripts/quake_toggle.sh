#!/usr/bin/env bash
# Quake drop-down terminal for niri.
# A floating kitty (app-id "quake") is parked on a declared named workspace
# "scratch" when hidden. Toggle: show on the active workspace, or hide to scratch.
# Requires: niri, kitty, jq. "scratch" workspace is declared in config.kdl.
set -euo pipefail
APPID="quake"
SCRATCH="scratch"

win=$(niri msg --json windows | jq -c ".[] | select(.app_id==\"$APPID\")" | head -n1)

# Not running yet -> launch (window-rule open-floating floats it on the current ws).
if [ -z "$win" ]; then
    kitty --app-id "$APPID" & disown
    exit 0
fi

win_id=$(jq '.id' <<<"$win")
win_ws=$(jq '.workspace_id' <<<"$win")

active=$(niri msg --json workspaces | jq -c '.[] | select(.is_active)' | head -n1)
active_id=$(jq '.id' <<<"$active")
active_idx=$(jq '.idx' <<<"$active")

if [ "$win_ws" = "$active_id" ]; then
    # Visible on the active workspace -> hide to scratch.
    niri msg action move-window-to-workspace "$SCRATCH" --window-id "$win_id"
else
    # Hidden (on scratch or elsewhere) -> bring to active workspace and focus.
    niri msg action move-window-to-workspace "$active_idx" --window-id "$win_id" --focus true
    niri msg action focus-window --id "$win_id"
fi
