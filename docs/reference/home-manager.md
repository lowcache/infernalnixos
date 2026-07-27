# Home Manager Modules

The `lowcache` user environment is assembled in
[`home/`](https://github.com/lowcache/volnixos/tree/main/home).
[`home/default.nix`](https://github.com/lowcache/volnixos/blob/main/home/default.nix) is the entry
point and imports the rest:

```nix
imports = [ ./persist.nix ./pkgs.nix ./scripts.nix ./shell.nix ];
```

| Module        | Responsibility                                                                |
| :------------ | :--------------------------------------------------------------------------- |
| `default.nix` | Session variables (Wayland backends, portals), GTK theme, cursor, Antigravity desktop entries |
| `pkgs.nix`    | User packages, grouped (dev, niri/Noctalia stack, fonts, terminal, AI CLIs) |
| `persist.nix` | Impermanence `/persist` mappings + out-of-store dotfile symlinks              |
| `scripts.nix` | Tor wrappers, agent-tool `~/.local/bin` symlinks (tether, agent-scaffold)      |
| `shell.nix`   | Fish (init/aliases/functions), git (SSH signing), starship, direnv, micro, ssh-agent |

## Session variables (`default.nix`)

A single `sessionVariables` set is applied to both `home.sessionVariables` and
`systemd.user.sessionVariables`. It sets the Wayland session (`XDG_SESSION_TYPE=wayland`, `QT_QPA_PLATFORM=wayland`,
`NIXOS_OZONE_WL=1`, `GTK_USE_PORTAL=1`, …). `XDG_CURRENT_DESKTOP` is deliberately **not** hardcoded —
`niri-session` exports it itself.

## Packages (`pkgs.nix`)

`home.packages` concatenates themed groups:

| Group        | Highlights                                                                  |
| :----------- | :------------------------------------------------------------------------- |
| `basedevel`  | gcc, cmake, gnumake, go, python3, nodejs, dart-sass                         |
| `niri`       | niri + Noctalia v5 + xwayland-satellite + file managers (cosmic-files, caja, …) |
| `wayland`    | fuzzel, kitty, **floorp-bin**, spotify, vscodium, file-roller, grim/slurp/swappy |
| `typography` | material-symbols + a large Nerd Fonts selection                            |
| `terminal`   | fish, git, gh, eza, bat, ripgrep, fd, jq, sops, micro, nil, `volinit`       |
| `nixified-ai`| claude-code, gemini-cli, rtk, MCP servers, `llm-agents` packages            |

!!! note "Krita native Wayland"
    Krita runs as a native Wayland client under niri. Previously on Hyprland, it was wrapped to force `QT_QPA_PLATFORM=xcb` to avoid canvas freezes, but niri handles the native Wayland Qt6 client smoothly.

## Browsers

Brave is installed through the `programs.chromium` Home Manager module (in `shell.nix`), which both
provides the package (`package = pkgs.brave`) and applies Wayland/GPU command-line flags. Floorp
(`floorp-bin`) is the backup browser, added to `home.packages` in `pkgs.nix`.

## Persistence & symlinks (`persist.nix`)

See [Impermanence](../architecture/impermanence.md). This module declares the `/persist` directory and
file lists, the `mkOutOfStoreSymlink` dotfile mappings, and the `~/volnix` alias.

## Agent tooling (`scripts.nix`)

Symlinks graduated agent tools (`tether` from `CodeRepo/tether` and `agent-scaffold` from `.nix-config/scripts`) into `~/.local/bin` (out-of-store, live-editable). The `memd` tool and its `memd-sweep` timer are deployed declaratively via the `services.memd` module. See [Agent Toolchain](../tooling/agents.md).
