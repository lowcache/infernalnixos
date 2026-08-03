---
type: todo
project: Vol NixOS
last_updated: 2026-08-02
status: active
---

# Open Tasks and Enhancement Roadmap (`memory/todo.md`)

---

## IN PROGRESS / AWAITING USER ACTION

### Noctalia Bar — Dual Wrap-Around Layout (2026-06-22 — LIVE, CAPTURE PENDING)

**Status:** Live and fully styled in runtime `~/.local/state/noctalia/settings.toml`, user-approved ("awesome"). **NOT yet committed to git.**

**Steps (in order):**
- [ ] Capture runtime state to `dots/noctalia/config.toml`
- [ ] Commit Ayu Green color-engine theme (`dots/color-engine/themes/ayu_green.json`)
- [ ] Commit regenerated dotfiles (`dots/kitty/`, `dots/starship/starship.toml`)

**Lower priority than other work.**

### Windows 11 VM — Installation In Progress

**Status:** OOBE in progress (as of 2026-06-19, unchanged). User rebooted 2026-07-09; verify post-reboot state.

**Next steps (in order):**
- [ ] **Post-reboot:** Verify Windows 11 VM still accessible via virt-manager console.
- [ ] Complete OOBE (network/account setup)
- [ ] Reach Windows desktop; verify graphics/audio/network
- [ ] Run assessment environment prerequisite check
- [ ] If assessment starts, report first prompt/task
- [ ] (Deferred) GPU passthrough + virtio optimization post-assessment

### XWayland Satellite Startup — Permanent niri Integration (2026-06-23 — PENDING)

**Status:** Manual test successful (FireAlpaca xcb-only AppImage runs with `xwayland-satellite :0` + `DISPLAY=:0 QT_QPA_PLATFORM=xcb`).

**Steps:**
- [ ] Add `spawn-at-startup "xwayland-satellite" ":0"` to `dots/niri/config.kdl`
- [ ] Relogin to niri, verify `pgrep -af xwayland-satellite` shows `:0` instance
- [ ] Test: launch FireAlpaca without manual `:0` start (should work with permanent startup)
- [ ] (Optional) Create `.desktop` wrapper for FireAlpaca auto-setting `DISPLAY` + `QT_QPA_PLATFORM`

### Krita 6.0.1 + Font Gallery Plugin — User-Text Input Pending Test (2026-06-22 — DESIGN COMPLETE)

**Status:** Plugin implementation complete with user-text input, multi-line rendering validated standalone, layer insertion proven. Awaiting end-to-end test.

**Steps:**
- [ ] Restart Nix Krita cleanly (or verify on next boot)
- [ ] Type text in the Font Gallery docker input box
- [ ] Double-click a font
- [ ] Verify no crash and raster layer appears on canvas with user text

### SessionEnd Hook — Work-Routing (2026-06-18 — READY TO BUILD)

Implement path-prefix routing for `.memory/` inbox ingestion. See Decision #17.

**Decisions locked in:** #17 (amended), #18 (memd ✓ + tether ✓, scaffold pending), #19 (scripts/ ephemeralness).

**Steps (execute after memd/tether cutover verified):**
- [ ] Code the hook logic in memd or standalone tool: path-prefix check (dots/ → dots inbox, else → root)
- [ ] Register hook in `~/.claude/settings.json` as SessionEnd event
- [ ] Test with dummy work note: edit a dots file, create test note, verify routing on next sync

### Nix-on-Droid — Login-Path Bug Fix + Re-Add Agents (2026-08-02 — AWAITING UPSTREAM)

**Status:** First activation successful (generation 2 active). Home Manager activates fully, 626 packages installed zero-compilation. One upstream login-path bug remains: any shell attached to the terminal hangs under generation 2's `login-inner`.

**Evidence (2026-08-02):**
- Activation completes end-to-end without error
- `fish -i -c 'echo'` with full config: 0.463s (fast)
- `fish --no-config -i`: 0.022s (fast)
- `fastfetch`: 0.889s (fast, ruled out)
- Every component tested in isolation is fast
- `login sh -c '<cmd>'` works fine (no terminal attachment)
- `login bash --noprofile --norc` hangs on clean slate (not fish-specific)
- SIGINT never lands after 40+ minutes (blocked in syscall, not slow)

**Hypothesis:** Generation 2's `login-inner` terminal-attach path or proot's pty handling under Android 16.

**Workaround:** Generation 1 is available via rollback; recovery proven instant: `login sh -c 'nix-on-droid rollback'`.

**Next steps:**
- [ ] File upstream issue on nix-on-droid with timings and evidence
- [ ] Optional: drill into `login-inner.nix` terminal-setup code (may reveal a nixpkgs interaction)
- [ ] Once login issue is understood, test re-adding `droid/agents.nix` by halves
- [ ] Write blog series once phone is daily-usable

**Blocks on:** Upstream response or self-contained understanding of login-path pty handling.

### Nix-on-Droid Blog Series (2026-08-02 — DEFERRED, BLOCKS ON LOGIN FIX)

**Status:** V1 implementation complete and verified (laptop side). Awaits working phone shell (login-path fix) to validate end-to-end. Blog series deferred until the phone is daily-usable.

**Planned blog series (3-5 posts):**
- [ ] Architecture & portable layer strategy
- [ ] Device setup & Makefile targets
- [ ] MCP integration with phone-agent Termux shim
- [ ] (Optional) Performance profiling on aarch64
- [ ] (Optional) Troubleshooting & runtime gotchas (bootstrap paradox, recovery ladder)

**Lower priority than fixing login issue.**

---

## BACKLOG / DEFERRED
