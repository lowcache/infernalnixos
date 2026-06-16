# Dotfiles

The [`dots/`](https://github.com/lowcache/volnixos/tree/main/dots) tree holds all user-space
configuration. Its children are symlinked into `~/.config/` with
`config.lib.file.mkOutOfStoreSymlink` (see [Impermanence](../architecture/impermanence.md)), so edits
apply live without a rebuild.

```text
dots/
├── cava/                # audio visualizer: shaders + gradient themes
├── fastfetch/           # system info fetch (config.jsonc)
├── fuzzel/              # application launcher (fuzzel.ini + theme)
├── gemini/              # Gemini / Antigravity agent config (credentials git-ignored)
├── htop/                # process viewer (htoprc)
├── hypr/                # Hyprland: keybinds, idle/lock, shaders, quake, scripts
├── illogical-impulse/   # Quickshell theme engine: JSON themes + scripts + config.json
├── kitty/              # terminal: kitty.conf + tab_bar.py + current.conf
├── kitty_colorschemes/  # extra kitty colorschemes
├── quickshell/ii/       # bespoke Qt6/QML shell (modules, services, panel families)
├── starship/            # prompt (starship.toml)
└── wlogout/             # Wayland logout menu (layout + style.css)
```

Most of these are detailed in the [Desktop](../desktop/index.md) section. A quick reference:

| Dotfile             | Notable settings                                                          |
| :------------------ | :----------------------------------------------------------------------- |
| `hypr/`             | Keybinds route through Quickshell IPC with script fallbacks; idle/lock via hypridle/hyprlock; GLSL screen shaders; Kitty quake terminal |
| `quickshell/ii/`    | ~45 QML backend services + `ii`/`waffle` panel families + color/AI/thumbnail scripts |
| `illogical-impulse/`| JSON theme engine (`apply_theme.py`); themes: amalgamation, petrified_spittoon, radioactive_slime |
| `kitty/`            | PunkMono Nerd Font, fish shell, custom bottom tab bar, `listen_on unix:@mykitty` for live theming |
| `fuzzel/`           | Google Sans Flex, overlay layer, rounded borders                         |
| `wlogout/`          | Six session actions; kills client PIDs before logout/reboot/shutdown     |
| `cava/`             | Spectrum shaders + an 8-stop `tricolor` gradient theme                    |
| `starship/`         | Two-line powerline prompt, neon palette, `cmd_duration` notifications     |
| `fastfetch/`        | Auto logo, full module list (os/host/kernel/cpu/gpu/memory/…)            |

## Independent dotfiles history

`dots/` can be published with its own history without a separate repository, using `git subtree`. The
[Makefile](../tooling/makefile.md) wraps the workflow:

```bash
make dots-log                       # history scoped to dots/ (no remote needed)
make dots-split                     # regenerate the dots-history projection branch
make dots-remote URL=<git-url>      # add the standalone 'dotfiles' remote (once)
make dots-push                      # publish dots/ to dotfiles/main
make dots-pull                      # merge changes back into dots/
```

!!! warning "No secrets in `dots/`"
    `dots/` is public. The `dots/gemini/` runtime credential files (`oauth_creds.json`,
    `google_accounts.json`, tokens, history/tmp/state) are git-ignored. Only declarative config is
    tracked.
