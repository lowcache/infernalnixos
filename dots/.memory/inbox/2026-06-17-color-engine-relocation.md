# Color engine relocated out of dots/illogical-impulse (2026-06-17)

The theme tooling is compositor-agnostic (drives ii/Hyprland, kitty, starship,
AND niri/Noctalia), so it was moved out of the ii-specific dir.

## Moved (git mv) → `dots/color-engine/` (symlinked to `~/.config/color-engine`)
- `apply_theme.py` (the global colorscheme applier; now also emits the Noctalia
  M3 palette `~/.config/noctalia/palettes/volnix.json`)
- `make_theme.py`, `check_theme.py`
- `themes/` → `dots/color-engine/themes/` (amalgamation, petrified_spittoon,
  radioactive_slime)
- Left behind in `dots/illogical-impulse/scripts/`: `apply_theme.bin`,
  `apply_theme.dist/` (nuitka build artifacts; regenerable, not relocated).

## Reference updates
- `dots/quickshell/ii/scripts/colors/switchwall.sh` (2 sites): apply_theme path
  → `~/.config/color-engine/apply_theme.py`.
- `dots/illogical-impulse/config.json` `masterTheme.jsonPath`: was stale
  `amalgamation.json`; corrected to `~/.config/color-engine/themes/radioactive_slime.json`
  (radioactive_slime = the active "toxic" neon scheme; verified its palette matches
  the live kitty colors #080B08/#39FF14/#B4FF00).
- `home/persist.nix`: new out-of-store symlink `~/.config/color-engine` → dots/color-engine.
- `apply_theme.py` still reads `~/.config/illogical-impulse/config.json` as the
  theme *selector* (persists under both sessions) — one remaining soft-link; can be
  fully decoupled later (e.g. ~/.config/color-engine/active.json).

## FIXED — switchwall.sh no longer hardcodes a theme
`switchwall.sh` invoked `apply_theme.py petrified_spittoon` — doubly wrong:
(1) hardcoded a specific theme (a wallpaper-setter must never choose a colorscheme),
(2) passed a bare NAME, not a path, so apply_theme hit `os.path.exists()==False` and
no-op'd — meaning the post-matugen restore never ran. Fixed: both call sites now run
`apply_theme.py` with NO arg, so it defers to the configured `masterTheme.jsonPath`
(the already-set theme). Design rule: callers outside apply_theme.py never name a
theme — they use the configured one. (This vendored ii script's apply_theme.py calls
are a local addition; upstream ii doesn't invoke it.)

## Caveat
ii's in-shell theme picker (if it lists ~/.config/illogical-impulse/themes/) will no
longer see the themes; theming via setwall/apply_theme is unaffected.

## Activation
Needs `make switch` — the `~/.config/color-engine` symlink is created at rebuild.
Until then the relocated paths don't exist at the old ii location.
