#!/usr/bin/env bash
# Quake drop-down terminal control for niri.
#
# ARCHITECTURE: niri only *spawns this script*. Every window operation — show,
# hide, toggle, edge/position, size, orientation — is performed by kitty's
# quick-access-terminal kitten over wlr-layer-shell + kitty remote control. The
# compositor never manages the window. niri is queried read-only (focused-output
# size) so "full" extents can be sized in pixels. This is the design that makes
# it perform like the Hyprland quake terminal.
#
# Controls are two-state TOGGLES hung off Mod+Return (see config.kdl). They are
# ORIENTATION-AWARE:
#   toggle       show / hide                        (Mod+Return)
#   position     landscape: top<->bottom            (Mod+Shift+Return)
#                portrait:  left<->right
#   size         normal <-> full extent             (Mod+Alt+Return)
#                landscape: short<->full height (lines)
#                portrait:  narrow<->full width  (columns)
#   orientation  landscape <-> portrait             (Mod+Ctrl+Return)
#                landscape = horizontal panel (top/bottom edge), full width
#                portrait  = vertical panel  (left/right edge), full height
#
# Layer-shell facts this relies on: horizontal (top/bottom) panels always span
# full width and size height via `lines` (`columns` ignored); vertical (left/
# right) panels always span full height and size width via `columns` (`lines`
# ignored). So orientation just selects which edge axis + which size dimension.
#
# Each axis remembers its own side: flipping orientation keeps your last
# top/bottom AND last left/right choice independently.
#
# Requires: kitty (kitten), niri, jq.
# Config:  ~/.config/kitty/quick-access-terminal.conf
set -euo pipefail

CONF="$HOME/.config/kitty/quick-access-terminal.conf"
RUNDIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
SOCK_GLOB="$RUNDIR/kitty-quake-*"
STATE="$RUNDIR/kitty-quake.state"

# --- tunables ------------------------------------------------------------------
NORMAL_LINES=25      # landscape "normal" height, in text rows
PORTRAIT_FRAC=50     # portrait "normal" width, as a percent of output width
# "full" height/width are derived from the focused output (whole screen).
# Defaults a fresh panel opens in:
DEF_ORIENT=landscape # landscape | portrait
DEF_POS_H=top        # top | bottom   (used while landscape)
DEF_POS_V=right      # left | right   (used while portrait)
DEF_SIZE=normal      # normal | full
# -------------------------------------------------------------------------------

# A missing socket (terminal not running yet) is a normal answer, not an error:
# `ls` exits non-zero on no match, and under `set -euo pipefail` that aborts the
# whole script at `s=$(sock)` on a cold start, so the panel could never launch the
# first time (it only worked once already running). On a tmpfs root /run is wiped
# every boot, so every boot started cold -> first keypress did nothing. `|| true`
# keeps the query non-fatal (empty output = not running).
sock() { ls -t $SOCK_GLOB 2>/dev/null | head -n1 || true; }

# WIDTH HEIGHT of the focused output, in logical pixels.
out_dim() { niri msg --json focused-output | jq -r '.logical | "\(.width) \(.height)"'; }

rc()    { local s=$1; shift; kitten @ --to "unix:$s" "$@"; }
panel() { local s=$1; shift; rc "$s" resize-os-window --action=os-panel --incremental "$@"; }

# --- persisted state -----------------------------------------------------------
state_reset() {
    printf 'orient=%s\npos_h=%s\npos_v=%s\nsize=%s\n' \
        "$DEF_ORIENT" "$DEF_POS_H" "$DEF_POS_V" "$DEF_SIZE" >"$STATE"
}
state_get() { [ -f "$STATE" ] || state_reset; sed -n "s/^$1=//p" "$STATE" | head -n1; }
state_set() {
    [ -f "$STATE" ] || state_reset
    if grep -q "^$1=" "$STATE"; then sed -i "s/^$1=.*/$1=$2/" "$STATE"
    else printf '%s=%s\n' "$1" "$2" >>"$STATE"; fi
}
flip() { [ "$1" = "$2" ] && printf '%s' "$3" || printf '%s' "$2"; } # flip CUR A B

# --- materialize the full geometry from current state --------------------------
apply() {
    local s=$1 w h orient size edge
    read -r w h < <(out_dim)
    orient=$(state_get orient); size=$(state_get size)
    if [ "$orient" = portrait ]; then
        edge=$(state_get pos_v)   # left | right -> full height automatically
        if [ "$size" = full ]; then panel "$s" "edge=$edge" "columns=${w}px"
        else panel "$s" "edge=$edge" "columns=$(( w * PORTRAIT_FRAC / 100 ))px"; fi
    else
        edge=$(state_get pos_h)   # top | bottom -> full width automatically
        if [ "$size" = full ]; then panel "$s" "edge=$edge" "lines=${h}px"
        else panel "$s" "edge=$edge" "lines=$NORMAL_LINES"; fi
    fi
}

# --- lifecycle -----------------------------------------------------------------
launch() { # start singleton (shows it), seed state, return socket when ready
    # setsid -f fully detaches into its own session so the panel outlives this
    # script (the kitten's own --detach is unreliable when spawned without a tty).
    setsid -f kitten quick-access-terminal -c "$CONF" >/dev/null 2>&1
    state_reset
    local s
    for _ in $(seq 1 30); do s=$(sock); [ -n "$s" ] && { printf '%s' "$s"; return 0; }; sleep 0.1; done
    return 1
}
ensure() { # ensure running + visible; echo socket
    local s; s=$(sock)
    if [ -z "$s" ]; then s=$(launch); else rc "$s" resize-os-window --action=show >/dev/null 2>&1 || true; fi
    printf '%s' "$s"
}

cmd=${1:-toggle}
case "$cmd" in
    toggle)
        s=$(sock)
        if [ -z "$s" ]; then launch >/dev/null; else rc "$s" resize-os-window --action=toggle-visibility; fi ;;
    show)   ensure >/dev/null ;;
    hide)   s=$(sock); [ -n "$s" ] && rc "$s" resize-os-window --action=hide || true ;;

    # orientation-aware toggles
    position)
        s=$(ensure)
        if [ "$(state_get orient)" = portrait ]; then
            state_set pos_v "$(flip "$(state_get pos_v)" left right)"
        else
            state_set pos_h "$(flip "$(state_get pos_h)" top bottom)"
        fi
        apply "$s" ;;
    size)
        s=$(ensure); state_set size "$(flip "$(state_get size)" normal full)"; apply "$s" ;;
    orientation)
        s=$(ensure); state_set orient "$(flip "$(state_get orient)" landscape portrait)"; apply "$s" ;;

    # explicit setters
    top)       s=$(ensure); state_set orient landscape; state_set pos_h top;    apply "$s" ;;
    bottom)    s=$(ensure); state_set orient landscape; state_set pos_h bottom; apply "$s" ;;
    left)      s=$(ensure); state_set orient portrait;  state_set pos_v left;   apply "$s" ;;
    right)     s=$(ensure); state_set orient portrait;  state_set pos_v right;  apply "$s" ;;
    landscape) s=$(ensure); state_set orient landscape; apply "$s" ;;
    portrait)  s=$(ensure); state_set orient portrait;  apply "$s" ;;
    normal)    s=$(ensure); state_set size normal; apply "$s" ;;
    full)      s=$(ensure); state_set size full;   apply "$s" ;;

    *) echo "usage: $0 {toggle|show|hide|position|size|orientation|top|bottom|left|right|landscape|portrait|normal|full}" >&2; exit 2 ;;
esac
