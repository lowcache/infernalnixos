---
type: todo
project: Vol NixOS — Dots
last_updated: 2026-06-18
status: active
---

# Dotfiles Open Tasks (`dots/.memory/todo.md`)

Open loops and pending verification for the `dots/` subtree. Scoped layer beneath repo-root
[`todo.md`](file:///home/lowcache/.nix-config/.memory/todo.md). Move done items to
[`archive/`](file:///home/lowcache/.nix-config/dots/.memory/archive/).

## Open

* [ ] **`make switch` needed to activate `~/.config/color-engine` symlink.** Added to
  `home/persist.nix` 2026-06-17, no rebuild run yet. Until then, `apply_theme.py` /
  `make_theme.py` / `check_theme.py` / `themes/` are only at `dots/color-engine/` relative
  paths, not the live `~/.config/color-engine/` path that scripts expect post-switch.

* [ ] **Decide whether to publish the dotfiles subtree.** If yes: create a standalone repo,
  then `make dots-remote URL=<git-url>` and `make dots-push`. If no: `make dots-log` /
  `make dots-split` are enough for an independent local history view. (No remote configured
  yet as of 2026-06-09.)

* [ ] **First `make dots-split` run is untested** — it walks full history and builds the
  `dots-history` branch. Run once to confirm it succeeds on this repo's history size.

* [ ] **Optional: decouple `apply_theme.py` theme selector from ii config.** Currently reads
  `~/.config/illogical-impulse/config.json`. Could migrate to `~/.config/color-engine/active.json`
  for full compositor-agnosticism. Low urgency — works across both compositors as-is.

* [ ] **Optional: compositor-agnostic touchpad toggle via kernel `inhibited` sysfs.** A udev
  rule granting `users`/`input` group write to the device's `inhibited` file would avoid the
  current niri workaround (config-marker flip + load-config-file). Needs rebuild + reboot.
  Current `touchpad_toggle.sh` approach is functional; this is a cleanup option only.

## Done / Verified

* [x] `#90C722q` colorscheme typo fixed and theme re-applied (2026-06-09).
* [x] Palette validation added to `apply_theme.py` (2026-06-09).
* [x] Color engine relocated to `dots/color-engine/`; `switchwall.sh` and `config.json`
  references updated; `home/persist.nix` symlink added (2026-06-17).
* [x] Quake drop-down terminal: Hyprland → niri port COMPLETE with orientation-aware
  keybinds (2026-06-18). `quake_toggle.sh` deleted. All four Mod+Return controls verified
  live against running panel on 1920×1200.
* [x] `dots` registered as memd project; `memd.py transcript_files` patched for
  longest-prefix exclusion; dots sync pipeline verified (2026-06-18).
