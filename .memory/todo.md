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

### Nix-on-Droid Activation — PTY Failure Bisect (2026-08-02 — BLOCKING)

**Status:** First switch on phone fails during `installPackages` phase with "getting pseudoterminal attributes: Permission denied". Three prior on-device issues resolved; this one remains. Root cause narrowed but not identified.

**What's ruled out** (verified by direct on-device test):
- NOT general pty unavailability (trivial derivations build, small user-environment builds succeed)
- NOT nix version (2.18.8 is fine)
- NOT TMPDIR or disk space issues
- Specific to building user-environment from ~500-package nix-on-droid-path closure

**In progress:**
- Bisect by dropping `droid/agents.nix` to test if closure size is the trigger (commit `fa3276aa…` on origin/main)
- If activation succeeds: re-add packages in halves until failure point
- If activation fails identically: cause is in `home/common` or nix-on-droid system layer

**Next step:** User runs `nix-on-droid switch --flake github:lowcache/volnixos/fa3276aa01cd07dd9f09ac24e129182cf63b4401` on phone (currently downloading cached paths). See `mistakes.md #13–14` for full diagnostic sequence.

**Blocker on:** Achieving working phone shell. Desktop side is complete and verified.

### Nix-on-Droid Blog Series (2026-08-02 — DEFERRED, BLOCKS ON ACTIVATION FIX)

**Status:** V1 implementation complete and verified (laptop side). Awaits working phone to validate end-to-end. Blog series deferred until activation PTY issue is resolved.

**Planned blog series (3-5 posts):**
- [ ] Architecture & portable layer strategy
- [ ] Device setup & Makefile targets
- [ ] MCP integration with phone-agent Termux shim
- [ ] (Optional) Performance profiling on aarch64
- [ ] (Optional) Troubleshooting & runtime gotchas

**Lower priority than fixing activation.

---

## BACKLOG / DEFERRED
