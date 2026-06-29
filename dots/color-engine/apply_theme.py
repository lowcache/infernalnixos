#!/usr/bin/env python3
import json, os, subprocess, sys, re

# Paths
KITTY_COLORS = os.path.expanduser("~/.config/kitty/current.conf")
KITTY_TABBAR = os.path.expanduser("~/.config/kitty/tab_bar.py")
STARSHIP_TOML = os.path.expanduser("~/.config/starship.toml")
KITTY_SOCKET = "unix:@mykitty"  # matches `listen_on unix:@mykitty` in kitty.conf

def validate_palette(palette):
    """Return a list of (name, value, reason) for any palette entry that is not a
    valid hex color. QML accepts #RGB, #RGBA, #RRGGBB, #AARRGGBB (3/4/6/8 hex digits).
    A single bad literal (e.g. "#90C722q") can make a consumer fail to load the entire
    config, so the apply is aborted before any files are written."""
    bad = []
    for name, value in palette.items():
        if not isinstance(value, str):
            bad.append((name, value, "not a string"))
            continue
        v = value.strip()
        if not re.fullmatch(r"#?[0-9A-Fa-f]+", v):
            bad.append((name, value, "contains non-hex characters"))
            continue
        digits = len(v.lstrip("#"))
        if digits not in (3, 4, 6, 8):
            bad.append((name, value, f"{digits} hex digits (expected 3, 4, 6, or 8)"))
    return bad


def apply_theme(theme_path, verbose=False):
    if not os.path.exists(theme_path):
        if verbose: print(f"Error: Theme file not found at {theme_path}")
        return False
    
    try:
        with open(theme_path, "r") as f:
            theme = json.load(f)
    except Exception as e:
        if verbose: print(f"Error parsing theme JSON: {e}")
        return False

    palette = theme.get("palette", {})
    mappings = theme.get("mappings", {})
    
    if not palette:
        if verbose: print("Error: No palette found in theme file.")
        return False

    # Fail fast on bad colors so nothing is written to the live (symlinked) configs.
    bad_colors = validate_palette(palette)
    if bad_colors:
        print(f"Error: invalid hex color(s) in palette '{theme_path}' — aborting, no files written:", file=sys.stderr)
        for name, value, reason in bad_colors:
            print(f"  - {name}: {value!r} ({reason})", file=sys.stderr)
        return False

    # Get standard colors
    bg = palette.get(mappings.get("surfaces", {}).get("main_bg"), "#1c1c1c")
    primary = palette.get(mappings.get("accents", {}).get("primary_active"), "#e78a53")
    secondary = palette.get(mappings.get("accents", {}).get("secondary_active"), "#fbcb97")
    fg = palette.get(mappings.get("text", {}).get("normal"), "#c1c1c1")

    # Helper for RGB (no #)
    def to_rgb(hex_val): return hex_val.lstrip("#")

    bg_rgb = to_rgb(bg)
    primary_rgb = to_rgb(primary)
    secondary_rgb = to_rgb(secondary)
    fg_rgb = to_rgb(fg)

    # Resolve the 16 terminal colors once; shared by kitty (color0-15) and the
    # Noctalia palette terminal block so they never drift apart.
    term_map = mappings.get("terminal", {})
    term_names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
                  "bright_black", "bright_red", "bright_green", "bright_yellow",
                  "bright_blue", "bright_magenta", "bright_cyan", "bright_white"]
    term_hex = []
    for name in term_names:
        cname = term_map.get(name)
        val = palette.get(cname) if cname else None
        if val and not val.startswith("#"): val = "#" + val
        term_hex.append(val)

    # 1. Kitty current.conf
    try:
        kitty_content = f"# Generated\nbackground {bg}\nforeground {fg}\nselection_background {primary}\nselection_foreground {bg}\ncursor {primary}\n"
        kitty_content += f"active_tab_foreground {bg}\nactive_tab_background {primary}\ninactive_tab_foreground {secondary}\ninactive_tab_background {bg}\ntab_bar_background {bg}\n"

        for i, val in enumerate(term_hex):
            if val: kitty_content += f"color{i} {val}\n"

        with open(KITTY_COLORS, "w") as f: f.write(kitty_content)
        if verbose: print("Updated Kitty current.conf")
    except Exception as e:
        if verbose: print(f"Error updating Kitty: {e}")

    # 3b. Live-apply to running kitty windows over the remote-control socket (no restart).
    # Tab-bar colors aren't settable via set-colors; the USR1 reload (in __main__) covers those.
    try:
        setcolors = [f"background={bg}", f"foreground={fg}", f"cursor={primary}",
                     f"selection_background={primary}", f"selection_foreground={bg}"]
        for i, val in enumerate(term_hex):
            if val: setcolors.append(f"color{i}={val}")
        r = subprocess.run(["kitty", "@", "--to", KITTY_SOCKET, "set-colors", "--all", "--configured", *setcolors],
                           capture_output=True, text=True)
        if verbose:
            print("Pushed colors to live kitty windows" if r.returncode == 0
                  else f"Kitty live set-colors skipped ({r.stderr.strip() or 'no listening instance'})")
    except FileNotFoundError:
        if verbose: print("Kitty live set-colors skipped (kitty not on PATH)")

    # 4. Kitty tab_bar.py
    if os.path.exists(KITTY_TABBAR):
        try:
            with open(KITTY_TABBAR, "r") as f: content = f.read()
            content = re.sub(r"ACTIVE_BG = as_rgb\(0x[0-9a-fA-F]+\)", f"ACTIVE_BG = as_rgb(0x{primary_rgb})", content)
            content = re.sub(r"ACTIVE_FG = as_rgb\(0x[0-9a-fA-F]+\)", f"ACTIVE_FG = as_rgb(0x{bg_rgb})", content)
            content = re.sub(r"ICON_BG = as_rgb\(0x[0-9a-fA-F]+\)", f"ICON_BG = as_rgb(0x{bg_rgb})", content)
            content = re.sub(r"INACTIVE_BG = as_rgb\(0x[0-9a-fA-F]+\)", f"INACTIVE_BG = as_rgb(0x{bg_rgb})", content)
            content = re.sub(r"INACTIVE_FG = as_rgb\(0x[0-9a-fA-F]+\)", f"INACTIVE_FG = as_rgb(0x{secondary_rgb})", content)
            with open(KITTY_TABBAR, "w") as f: f.write(content)
            if verbose: print("Updated Kitty tab_bar.py")
        except Exception as e:
            if verbose: print(f"Error updating tab_bar.py: {e}")

    # 5. Starship.toml
    if os.path.exists(STARSHIP_TOML):
        try:
            with open(STARSHIP_TOML, "r") as f: content = f.read()
            
            # Ensure palette = "current"
            content = re.sub(r'^palette = ".*"', 'palette = "current"', content, flags=re.MULTILINE)
            
            # Rebuild [palettes.current]
            palette_section = f'[palettes.current]\n'
            palette_section += f'black = "{bg}"\n'
            palette_section += f'red = "{palette.get(term_map.get("red"), primary)}"\n'
            palette_section += f'green = "{palette.get(term_map.get("green"), secondary)}"\n'
            palette_section += f'yellow = "{primary}"\n'
            palette_section += f'blue = "{secondary}"\n'
            palette_section += f'magenta = "{palette.get(term_map.get("magenta"), primary)}"\n'
            palette_section += f'cyan = "{palette.get(term_map.get("cyan"), secondary)}"\n'
            palette_section += f'white = "{fg}"\n'

            # Replace any existing palette section like [palettes.ps] or [palettes.current]
            content = re.sub(r'\[palettes\..*\](\n.*)*', palette_section, content)
            
            with open(STARSHIP_TOML, "w") as f: f.write(content)
            if verbose: print("Updated starship.toml")
        except Exception as e:
            if verbose: print(f"Error updating starship: {e}")

    # 6. Noctalia v5 palette (Material 3) — ADDITIVE. Writes the custom palette
    # consumed by the niri/Noctalia session (theme.source="custom",
    # custom_palette="volnix"); hot-reloaded live by Noctalia on file change.
    # Wrapped in its own try/except so it never affects the ii outputs above.
    NOCTALIA_PALETTE = os.path.expanduser("~/.config/noctalia/palettes/volnix.json")
    def _resolve(section, role):
        key = mappings.get(section, {}).get(role)
        v = palette.get(key) if key else None
        if v and not v.startswith("#"): v = "#" + v
        return v
    def _pick(*cands):
        for c in cands:
            if c: return c
        return None
    try:
        roles = {
            "mPrimary":          _pick(_resolve("accents", "primary_active"), primary),
            "mOnPrimary":        _pick(_resolve("text", "on_primary"), bg),
            "mSecondary":        _pick(_resolve("accents", "secondary_active"), secondary),
            "mOnSecondary":      _pick(_resolve("text", "on_secondary"), bg),
            "mTertiary":         _pick(_resolve("accents", "tertiary_active"), secondary),
            "mOnTertiary":       _pick(_resolve("text", "on_tertiary"), bg),
            "mError":            _pick(_resolve("states", "error"), "#ffb4ab"),
            "mOnError":          _pick(_resolve("states", "on_error"), bg),
            "mSurface":          _pick(_resolve("surfaces", "main_bg"), bg),
            "mOnSurface":        _pick(_resolve("text", "on_surface"), _resolve("text", "normal"), fg),
            "mSurfaceVariant":   _pick(_resolve("surfaces", "surface_variant"), bg),
            "mOnSurfaceVariant": _pick(_resolve("text", "on_surface_variant"), fg),
            "mOutline":          _pick(_resolve("accents", "outline"), secondary),
            "mShadow":           "#000000",
            "mHover":            _pick(_resolve("surfaces", "surface_container_high"), bg),
            "mOnHover":          _pick(_resolve("text", "on_surface"), _resolve("text", "normal"), fg),
        }
        tnames = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
        on_surface = roles["mOnSurface"]
        term_block = {
            "background": roles["mSurface"], "foreground": on_surface,
            "cursor": roles["mPrimary"], "cursorText": roles["mSurface"],
            "selectionBg": roles["mPrimary"], "selectionFg": roles["mSurface"],
            "normal": {n: (term_hex[i] or on_surface) for i, n in enumerate(tnames)},
            "bright": {n: (term_hex[i + 8] or on_surface) for i, n in enumerate(tnames)},
        }
        dark = dict(roles); dark["terminal"] = term_block
        os.makedirs(os.path.dirname(NOCTALIA_PALETTE), exist_ok=True)
        with open(NOCTALIA_PALETTE, "w") as f:
            json.dump({"dark": dark}, f, indent=2)
        if verbose: print("Updated Noctalia palette (volnix.json)")
    except Exception as e:
        if verbose: print(f"Error updating Noctalia palette: {e}")

    return True

if __name__ == "__main__":
    try:
        theme_path = ""
        verbose = False
        if len(sys.argv) > 1: theme_path = os.path.expanduser(sys.argv[1])
        if len(sys.argv) > 2: verbose = sys.argv[2].lower() == "true"
        if apply_theme(theme_path, verbose):
            subprocess.run(["killall", "-USR1", "kitty"], capture_output=True)
            if verbose: print("Theme Applied Successfully.")
    except Exception as e:
        print(f"Critical Error: {e}")
        sys.exit(1)
