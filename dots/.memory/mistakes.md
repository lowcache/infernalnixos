---
type: mistakes
project: Vol NixOS — Dots
last_updated: 2026-06-18
status: active
---

# Dotfiles Mistakes Log (`dots/.memory/mistakes.md`)

Append-only audit log of config mistakes in the `dots/` subtree, their cause, and the exact
prevention rule. Move resolved/obsolete entries to
[`archive/`](file:///home/lowcache/.nix-config/dots/.memory/archive/) to keep this concise.

---

## M1 — Invalid hex color broke the entire Quickshell config (2026-06-09)

* **Symptom:** Quickshell: *"failed to load configuration — illogical-impulse: family
  unavailable: illogical-impulse."* The whole illogical-impulse shell/rice failed to load.
* **Cause:** A typo in the palette `themes/amalgamation.json` — `"dark_teal": "#90C722q"`
  (stray `q`, 7 chars, non-hex). `apply_theme.py` propagated it into `Appearance.qml`
  (`m3primaryFixedDim: "#90C722q"`). QML cannot parse an invalid color literal, so the
  `Appearance` singleton — the root of the config — failed to construct, taking the whole
  shell down with it.
* **Fix:** Corrected the palette to `"#90C722"`, re-ran
  `python3 scripts/apply_theme.py <palette.json> true`. The generated `Appearance.qml`
  (symlinked from `dots/`) updated to a valid value; no other invalid hex present.
* **Prevention rule:** After editing any palette/theme JSON, validate every value is a
  valid `#RRGGBB` or `#AARRGGBB` literal (6/8 hex chars, no stray characters) **before**
  applying. A single bad color cascades into a total Quickshell load failure, not a
  localized glitch. Fix at the palette source, never by hand-editing generated outputs.

### 2026-06-18 — Killing kitty by raw PID closed the live terminal session

* **Symptom:** User's active kitty terminal window closed mid-session.
* **Cause:** The assistant ran `kill <PIDs>` targeting processes identified only by socket
  name pattern (`@kitty-ipc-...-quick-access`). The user's live terminal also holds open
  sockets via `kitty.conf`'s `listen_on unix:@mykitty-<pid>`. PID identification was
  incomplete; kill by raw PID is non-recoverable for open terminal sessions.
* **Prevention rule:** Never kill kitty processes by raw PID. To close a quake panel:
  use its own per-instance RC socket (`$XDG_RUNTIME_DIR/kitty-quake-<pid>`). The
  `@mykitty-<pid>` abstract socket belongs to the user's live terminal — treat any
  process holding it as untouchable. When in doubt about PID identity, read-only
  inspect (`ss -xlp`, `ls /proc/<pid>/fd`) before sending any signal.

### 2026-06-18 — kitty inline comment on option line caused silent quake launch failure

* **Symptom:** `quick-access-terminal` kitten launched and immediately exited; no RC
  socket appeared; `quake.sh` had nothing to drive. No error to stdout.
* **Cause:** `quick-access-terminal.conf` had `edge top  # the horizontal anchor`. In
  kitty config, everything after the value on a line IS the value — the comment text
  became part of the edge string, which is not a valid identifier. kitty exits silently
  on invalid kitten config options.
* **Prevention rule:** kitty config files (including kitten `.conf` files) have **no
  inline comments**. Place all comments on their own dedicated lines. Symptom signature:
  kitten exits immediately with no socket and no stderr output.

### 2026-06-18 — `columns` silently ignored on horizontal kitty layer-shell panels

* **Symptom:** `quake.sh apply_aspect` sent `resize-os-window --action=os-panel
  --incremental columns=<N>` to a top-edge panel — exit 0, zero visible width change.
* **Cause:** kitty wlr-layer-shell axis rule: top/bottom (horizontal) panels always span
  full width and size HEIGHT via `lines`; `columns` is silently ignored. Width on
  horizontal panels is controlled by `margin-left`/`margin-right` (field names use
  **dashes**, unlike bare `edge`/`lines`/`columns`).
* **Prevention rule:** Horizontal panel (top/bottom edge): width = `margin-left`/`margin-right`,
  height = `lines`. Vertical panel (left/right edge): width = `columns`, height automatic
  (full). Portrait quake must use a real vertical edge (`edge=left`/`right`), not a
  margin-narrowed horizontal strip — vertical panels get full height automatically and
  size width correctly via `columns`.
