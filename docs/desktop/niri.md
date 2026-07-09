# Niri Compositor & UWSM

The session is managed by the Universal Wayland Session Manager (UWSM). Login is handled via `greetd` and `tuigreet`, which launches the session. Niri is configured as the sole graphical session and is enabled via `programs.niri.enable` directly in `nixos/configuration.nix`.

!!! note
    The configuration file is a live-edit out-of-store symlink pointing to `dots/niri/config.kdl` at `~/.config/niri`. Home Manager does not write files here.

## X11 Support

Legacy X11 applications are supported via `xwayland-satellite` running on display `:0`. This ensures both Flatpak Qt5 apps (using the xcb plugin) and xcb-only AppImages run seamlessly.

## Keybinds

### System & Launchers

App launchers are dynamically resolved via `~/.config/niri/scripts/launch_first_available.sh`.

| Action | Keybind |
|---|---|
| File Manager | `Mod` + `E` |
| Browser | `Mod` + `W` |
| Code Editor | `Mod` + `C` |
| Text Editor | `Mod` + `X` |
| Volume Mixer | `Ctrl` + `Mod` + `V` |
| Task Manager | `Ctrl` + `Shift` + `Escape` |
| Color picker (`hyprpicker`) | `Mod` + `Shift` + `C` |
| Session menu (`wlogout`) | `Ctrl` + `Alt` + `Delete` |

### Hardware & Session Controls

Media and brightness keys are routed via `noctalia msg` to integrate with the Noctalia shell.

| Action | Keybind |
|---|---|
| Toggle touchpad | `F10` |
| Media / Brightness | Hardware media keys |
| Lock session | `Mod` + `L` |

!!! tip
    While `Mod` + `L` triggers `loginctl lock-session`, the visual lock screen itself is provided by Noctalia.

### Workspace Management

| Action | Keybind |
|---|---|
| Move column to adjacent workspace | `Mod` + `Shift` + `Page_Up` / `Page_Down` |
| Move column to adjacent workspace | `Ctrl` + `Mod` + `Shift` + `Left` / `Right` |

## Quake Terminal

A fast drop-down terminal is provided using `kitten quick-access-terminal` and controlled by `dots/niri/scripts/quake.sh`.

| Action | Keybind |
|---|---|
| Toggle visibility | `Mod` + `Return` |
| Position terminal | `Mod` + `Shift` + `Return` |
| Adjust height | `Mod` + `Alt` + `Return` |
| Adjust aspect ratio | `Mod` + `Ctrl` + `Return` |

!!! warning
    The terminal uses an `on-demand` focus policy in `quick-access-terminal.conf` so Niri keybinds can continue functioning while the terminal panel is active.
