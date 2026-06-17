# home/noctalia.nix — Noctalia v5 shell (package + enable only).
# Config is deliberately NOT managed here: ~/.config/noctalia is an out-of-store
# symlink to dots/noctalia (see persist.nix), matching the ii/quickshell live-edit
# pattern (decision #1) and leaving apply_theme.py free to write the M3 palette at
# runtime (~/.config/noctalia/palettes/volnix.json, hot-reloaded).
# Additive & reversible: drop the ./noctalia.nix import from home/default.nix.
{ inputs, ... }:
{
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia.enable = true;
  # package is auto-set by homeModules.default (lib.mkDefault). systemd.enable is
  # left false (default) — niri spawn-at-startup launches noctalia. settings and
  # customPalettes are left empty so Home Manager writes NO files into the
  # symlinked config dir (avoids a collision with the out-of-store symlink).
}
