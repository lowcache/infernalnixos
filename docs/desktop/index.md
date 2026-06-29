# Desktop Stack Overview 🖥️

The desktop stack is a pure-Wayland ecosystem: the [niri](niri.md) scrollable-tiling compositor paired with the [Noctalia v5](noctalia.md) native shell and a JSON [Theming Engine](theming.md).

!!! info
    The desktop session runs [niri](niri.md) under the Universal Wayland Session Manager (UWSM), launched from `greetd`/`tuigreet`. The shell, bar, lock screen, and OSD are provided by [Noctalia v5](noctalia.md) (C++/native), styled by the JSON [Theming Engine](theming.md). This replaces the former Hyprland + Quickshell (ii) stack.

## Architecture

```mermaid
graph TD
    A[greetd + tuigreet] -->|uwsm start niri.desktop| B[UWSM]
    B --> C[niri]
    C --> D[Noctalia v5 shell]
    C --> E[kitty & Apps]
    F[Theming Engine] -.->|Applies Colors| D
    F -.->|Applies Colors| E
```

## Core Components

- **[niri Compositor](niri.md)**: The scrollable-tiling Wayland compositor — keybind routing, app launchers, lock via `loginctl`, and a `kitten`-based Quake drop-down terminal.
- **[Noctalia Shell](noctalia.md)**: The C++/native v5 shell that replaces panels and runners — bar, wallpaper picker, lock/idle, OSD, and the Claude Code companion plugin.
- **[Theming Engine](theming.md)**: A global JSON-based color scheme generator and applier (color-engine), accessible via Makefile targets.
