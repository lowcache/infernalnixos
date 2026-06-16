# Theming Engine

The desktop stack uses a global, JSON-based color scheme engine. Configuration and scripts are located in `dots/illogical-impulse/`.

## Themes

Themes are stored in the `themes/` directory as JSON files. Examples include:
- `amalgamation.json` ("Muted Amalgamation (Detailed)")
- `petrified_spittoon.json` ("Petrified Spittoon (Detailed)")
- `radioactive_slime.json` ("Radioactive Slime")

!!! note
    `amalgamation.json` serves as the canonical template and master theme. The configuration file `config.json` uses the `appearance.wallpaperTheming.masterTheme.jsonPath` key to reference it.

## Scripts & Engine

The theming tools map JSON palettes onto various applications live:

- `scripts/apply_theme.py`: Applies a JSON theme across the system via a `TECHNICAL_MAP`. Targets include Quickshell's `Appearance.qml`, `hypr/hyprland/colors.conf`, Starship (`starship.toml`), and `kitty` (`current.conf` + `tab_bar.py`). Kitty theming is applied live through a remote control socket (`unix:@mykitty`).
- `scripts/check_theme.py`: Validates JSON theme structures. It hard-fails on invalid hex values or dangling mapping references, and warns if roles are missing compared to `amalgamation.json`.
- `scripts/make_theme.py`: Generates new JSON themes from hex arguments or a color file. It derives backgrounds, accents, containers, dim variants, and a 16-color terminal set. This script also includes internal validation and an `--apply` flag for immediate deployment.

## Workflow & Makefile Targets

The engine is primarily operated through Makefile targets for ease of use:

| Command | Description |
|---|---|
| `make theme-list` | List available themes. |
| `make theme-apply THEME=<name>` | Apply a specific theme globally. |
| `make theme-check THEME=<name>` | Validate a theme JSON file. |
| `make theme-new NAME="..." [COLORS="#a #b"] [FROM=<file>] [APPLY=1] [FORCE=1]` | Generate a new theme from colors or an image. |

## Application Specifics

### Kitty Terminal Integration

The terminal environment is driven by a Home-Manager generated `kitty.conf` (located in `dots/kitty/`):
- Uses `fish` as the default shell.
- Font is "PunkMono Nerd Font" at size 11, with `symbol_map` settings for Nerd Font PUA ranges.
- Features a beam cursor with a `cursor_trail`.
- Contains a custom bottom tab bar powered by `tab_bar.py`.
- Integrates with the theming engine via `allow_remote_control` and `listen_on unix:@mykitty`.
- Additional colorschemes reside in `dots/kitty_colorschemes/` (e.g., `Custom.conf`, `"Modus Vivendi Tinted.conf"`).

### Fonts

The system designates specific font families for different UI roles:
- **Main**: "Google Sans Flex"
- **Monospace**: "JetBrains Mono NF"
- **Expressive**: "Space Grotesk"
- **Reading**: "Readex Pro"

## WorkSafety Policy

The engine includes a `workSafety` policy (defined in `config.json`, disabled by default). When active (`clipboard=false`, `wallpaper=false`), this policy intercepts and filters clipboard content and wallpaper displays if the system connects to specific wireless networks associated with public or professional environments.
