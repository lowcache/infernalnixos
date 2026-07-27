# Dotfiles

The [`dots/`](https://github.com/lowcache/volnixos/tree/main/dots) tree holds all user-space
configuration. Its children are symlinked into `~/.config/` with
`config.lib.file.mkOutOfStoreSymlink` (see [Impermanence](../architecture/impermanence.md)), so edits
apply live without a rebuild.

```text
dots/
├── .memory/             # memd project memory (state/decisions/mistakes/todo + inbox)
├── .model/              # agent-scaffold guides (CLAUDE.md etc.)
├── cava/                # audio visualizer: shaders + gradient themes
├── fastfetch/           # system info fetch (config.jsonc)
├── fuzzel/              # application launcher (fuzzel.ini + theme)
├── htop/                # process viewer (htoprc)
├── color-engine/        # JSON theme engine: apply_theme.py + themes/
├── kitty/              # terminal: kitty.conf + tab_bar.py + current.conf
├── kitty_colorschemes/  # extra kitty colorschemes
├── niri/                # niri compositor: config.kdl, scripts, quake terminal
├── noctalia/            # Noctalia v5 shell: config.toml + palettes/volnix.json
├── starship/            # prompt (starship.toml)
└── wlogout/             # Wayland logout menu (layout + style.css)
```

Most of these are detailed in the [Desktop](../desktop/index.md) section. A quick reference:

| Dotfile             | Notable settings                                                          |
| :------------------ | :----------------------------------------------------------------------- |
| `niri/`             | Keybinds, window rules, startup apps, IPC scripts, and Kitty quake terminal |
| `noctalia/`         | Noctalia v5 shell config (`config.toml`) + color-engine palette (`palettes/volnix.json`) |
| `color-engine/`     | JSON theme engine (`apply_theme.py`); themes mapped to Noctalia, Kitty, and Starship |
| `kitty/`            | PunkMono Nerd Font, fish shell, custom bottom tab bar, `listen_on unix:@mykitty` for live theming |
| `fuzzel/`           | Google Sans Flex, overlay layer, rounded borders                         |
| `wlogout/`          | Six session actions (lock, logout, suspend, hibernate, reboot, shutdown) |
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
    `dots/` is public — only declarative config is tracked. Runtime credentials and agent state (for
    example `~/.gemini`) live outside the repo as persisted `$HOME` directories, never in `dots/`.
