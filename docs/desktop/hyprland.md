# Hyprland & UWSM

The session is managed by the Universal Wayland Session Manager (UWSM). Login is handled via `greetd` and `tuigreet`, which launches the session using `uwsm start hyprland.desktop`.

!!! note
    Most keybinds are routed through Quickshell IPC (`quickshell:...`) to provide a cohesive UI. Fallback utilities (like `fuzzel`, `wlogout`, or bash scripts) are gated behind a liveness check using `qs ... ipc call TEST_ALIVE`. The primary modifier key (`Mod`) is `Super`.

## Keybinds

### Shell

| Action | Keybind |
|---|---|
| Toggle search/launcher (`fuzzel` fallback) | `Super` (tap `Super_L`/`Super_R`) |
| Overview | `Super` + `Tab` |
| Clipboard history (`cliphist`) | `Super` + `V` |
| Emoji picker | `Super` + `.` |
| Open left sidebar | `Super` + `A` / `B` / `O` |
| Detach left sidebar | `Super` + `Alt` + `A` |
| Open right sidebar | `Super` + `N` |
| Cheatsheet | `Super` + `/` |
| On-screen keyboard | `Super` + `K` |
| Media controls | `Super` + `M` |
| Overlay | `Super` + `G` |
| Toggle bar | `Super` + `J` |
| Session menu (`wlogout` fallback) | `Ctrl` + `Alt` + `Delete` |
| Welcome app | `Shift` + `Super` + `Alt` + `/` |
| Wallpaper selector | `Ctrl` + `Super` + `T` |
| Random wallpaper | `Ctrl` + `Super` + `Alt` + `T` |
| Restart widgets | `Ctrl` + `Super` + `R` |
| Cycle panel family | `Ctrl` + `Super` + `P` |

### Hardware Keys

| Action | Keybind |
|---|---|
| Brightness +/-5% (`brightnessctl` fallback) | `XF86MonBrightnessUp/Down` |
| Volume +/-2% (`wpctl`) | `XF86AudioRaiseVolume/LowerVolume` |
| Mute sink | `XF86AudioMute` or `Super` + `Shift` + `M` |
| Mute source | `XF86AudioMicMute` or `Super` + `Alt` + `M` |

### Utilities

| Action | Keybind |
|---|---|
| Region screenshot (`hyprshot` fallback) | `Super` + `Shift` + `S` |
| Google Lens region search | `Super` + `Shift` + `A` |
| OCR region to clipboard (`grim` + `slurp` + `tesseract`) | `Super` + `Shift` + `X` or `Super` + `Shift` + `T` |
| Color picker (`hyprpicker -a`, hex to clipboard) | `Super` + `Shift` + `C` |
| Fullscreen screenshot to clipboard | `Print` |
| Fullscreen screenshot to file | `Ctrl` + `Print` |
| Record region (no sound) | `Super` + `Shift` + `R` or `Super` + `Alt` + `R` |
| Record fullscreen (no sound) | `Ctrl` + `Alt` + `R` |
| Record fullscreen with sound | `Super` + `Shift` + `Alt` + `R` |

### Window Management

| Action | Keybind |
|---|---|
| Move window | `Super` + drag or `Super` + `Shift` + arrows |
| Resize window | `Super` + right-drag |
| Move focus | `Super` + arrows or `Super` + `[` / `]` |
| Close window | `Alt` + `F4` or `Super` + `Q` |
| Force kill (`hyprctl kill`) | `Super` + `Shift` + `Alt` + `Q` |
| Split ratio -/+0.1 | `Super` + `;` / `Super` + `'` |
| Toggle floating | `Super` + `Alt` + `Space` |
| Maximize | `Super` + `D` |
| Fullscreen | `Super` + `F` |
| Pin window | `Super` + `P` |
| Move window to workspace 1-10 | `Super` + `Alt` + `<num>` |
| Send window to scratchpad | `Super` + `Alt` + `S` |
| Toggle special workspace | `Ctrl` + `Super` + `S` |
| Resize active window to 640x480 | `Ctrl` + `Super` + `\` |

### Workspace Management

| Action | Keybind |
|---|---|
| Focus workspace 1-10 | `Super` + `<num>` |
| Focus relative workspace | `Ctrl` + `Super` + `Left/Right`, `Super` + scroll, `Super` + `Page_Up/Down` |
| Toggle scratchpad | `Super` + `S` |

### Session & Media

| Action | Keybind |
|---|---|
| Lock session (`loginctl lock-session`) | `Super` + `L` |
| Suspend | `Super` + `Shift` + `L` |
| Poweroff | `Ctrl` + `Shift` + `Alt` + `Super` + `Delete` |
| Media Next | `Super` + `Shift` + `N` or `XF86AudioNext` |
| Media Previous | `Super` + `Shift` + `B` or `XF86AudioPrev` |
| Media Play/Pause (`playerctl`) | `Super` + `Shift` + `P` or `XF86AudioPlay` |

### Screen & Apps

| Action | Keybind |
|---|---|
| Zoom out/in 0.3 | `Super` + `-` / `Super` + `=` |
| Terminal (`kitty -1`) | `Super` + `T` or `Ctrl` + `Alt` + `T` |
| File manager (`dolphin`) | `Super` + `E` |
| Browser (`brave`) | `Super` + `W` |
| Code editor (`antigravity/code`) | `Super` + `C` |
| Text editor | `Super` + `X` |
| Volume mixer (`pavucontrol`) | `Ctrl` + `Super` + `V` |
| Settings | `Super` + `I` |
| Task manager | `Ctrl` + `Shift` + `Escape` |

### Special Mapping & Overrides

| Action | Keybind |
|---|---|
| Enter/exit `virtual-machine` submap | `Super` + `Alt` + `F1` |
| Toggle touchpad (`toggle-touchpad.sh`) | `F10` and `XF86TouchpadToggle` |

!!! tip
    The `virtual-machine` submap disables normal keybinds to allow inputs to cleanly pass through to VMs.

## Idle & Lock

The idle daemon (`hypridle.conf`) monitors session activity:
- **600s (10 min)**: Triggers DPMS off (and restores DPMS on upon resume).
- **900s (15 min)**: Suspends the system (`systemctl suspend`).
- **1800s (30 min)**: Locks the session.
- **before_sleep**: Ensures the session is locked (`loginctl lock-session`).

The locking mechanism (`lock_cmd`) defaults to Quickshell's lock screen, with `hyprlock` as the fallback. 
- `hyprlock.conf` features an `rgba(181818FF)` background with a 250x50 centered input field. It displays keyboard layout, a Caps Lock warning (via `check-capslock.sh`), a 12-hour clock, the date, `$USER`, and a status line that refreshes every 5 seconds (`status.sh`). It also sources `hyprlock/colors.conf`.

## Shaders & Quake Terminal

- **Shaders**: Housed in `dots/hypr/shaders/`. The GLSL screen shaders include `chromatic_abberation.frag`, `crt.frag`, `drugs.frag`, `extradark.frag`, `invert.frag`, and `solarized.frag`.
- **Quake Terminal**: A drop-down `kitty` terminal located at `dots/hypr/quake/`. It spawns on workspace `special:quake` (`uwsm app -- kitty --single-instance --class quake`). 
    - `Super` + `Return`: Toggle terminal.
    - `Super` + `Shift` + `Return`: Move between top and bottom.
    - `Super` + `Alt` + `Return`: Toggle full size.
    - Sizing and per-monitor geometry are handled by `quake_toggle.sh` using `hyprctl monitors -j` and `jq` (defaults to a top height of 500).

!!! warning
    The `monitors.conf` and `workspaces.conf` files are stubs. They are intended to be overwritten by `nwg-displays`.
