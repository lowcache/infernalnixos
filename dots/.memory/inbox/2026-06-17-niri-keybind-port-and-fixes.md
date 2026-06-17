# niri first-session fixes: keybind port, quake, audio, border (2026-06-17)

First real niri/Noctalia session surfaced several issues; root cause was that
config.kdl was a minimal starter, not a port of the 191-bind Hyprland config.

## Audio (FIXED, runtime)
`hardware.bluetooth.enable = true` (added to nixos/niri.nix as a Noctalia dep)
let the Sony WH-CH700N auto-connect and grab the default sink → no speaker output.
Fix: `wpctl set-default 58` (Ryzen/Realtek analog stereo). NOTE: BT headset will
re-grab default when it connects; consider a WirePlumber rule to not auto-switch
default to bluez, or just pick output in Noctalia's audio panel.

## Keybinds (PORTED, live)
Translated dots/hypr/hyprland/keybinds.conf → dots/niri/config.kdl:
- Apps reuse ~/.config/hypr/hyprland/scripts/launch_first_available.sh (agnostic;
  consider relocating out of dots/hypr later). Super+Return=quake, Super+T=terminal,
  Super+E/W/C/X/I = files/browser/code/text/settings.
- Shell actions via `noctalia msg`: Super+Space=launcher (panel-toggle launcher),
  Super+Tab=toggle-overview (niri native), Super+A/N=control-center, Super+Period=
  launcher /emo, Super+Slash=show-hotkey-overlay, Super+J=bar-toggle, Super+M=
  control-center media, Super+V=cliphist|fuzzel.
- Window/workspace/media/screenshot/session binds mapped to niri actions.
- Launcher was Super-TAP under quickshell (niri can't do tap) → moved to Super+Space.

## Quake terminal (FIXED, tested)
quake_toggle.sh rewritten for niri: kitty app-id "quake", window-rule open-floating;
hide → move-window-to-workspace "scratch" (named, by name); show → move to active
workspace idx + focus-window --id. Verified launch/hide/show live.

## Workspaces (offset hack)
niri resolves numeric refs as INDEX, names as NAME. A declared named workspace is
always idx 1. So `workspace "scratch"` = idx 1, real dynamic workspaces = idx 2+.
Mod+1..9 are bound to focus-workspace 2..10 (skipping scratch). Clean idx ordering
needs a fresh niri login (mid-session reloads leave tangled/reversed indices +
leftover dynamic workspaces).

## Border (FIXED)
focus-ring active-color "#B4FF00" (neon). TODO: drive from color-engine (would need
apply_theme.py to patch config.kdl focus-ring; niri border is niri's own, not Noctalia).

## Touchpad toggle (FIXED, tested) — ASUS F10
Original: dots/hypr/hyprland/scripts/toggle-touchpad.sh (hyprctl device toggle),
bound F10 + XF86TouchpadToggle in dots/hypr/custom/keybinds.conf.
niri port: dots/niri/scripts/touchpad_toggle.sh flips an `// off // @tptoggle@`
marker line in config.kdl's touchpad block and runs `niri msg action load-config-file`
(niri has no runtime input IPC). Validated before reload; default/committed state
= enabled (off commented) so off->on returns to baseline (no net git diff). Bound
F10 + XF86TouchpadToggle. Tested both directions live.
CLEANER FOLLOW-UP (optional): touchpad exposes kernel `inhibited` at
/sys/.../0018:093A:2008.0003/input/inputN/inhibited (root-owned 0644). A declarative
udev rule granting the `users`/`input` group write would let a script echo 1/0 there
— compositor-agnostic, zero config churn — but needs a rebuild + reboot to test.

## Status
All changes are dots (live via symlink); no rebuild needed — activation immediate
via niri config reload. Commit pending (user handles commits).
