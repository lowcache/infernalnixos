---
type: todo
project: Vol NixOS
last_updated: 2026-08-03
status: active
---

# Open Tasks and Enhancement Roadmap (`memory/todo.md`)

---

## COMPLETE (2026-08-03)

### Nix-on-Droid — Generation 4 Live and Verified (2026-08-02 — VERIFIED WORKING)

✓ glibc 2.42 TCGETS2 regression diagnosed and fixed via nixos-25.11 pin
✓ Generation 4 activation successful end-to-end
✓ Fish shell interactive on cold start
✓ Shared `home/common/` layer ported intact (zero changes)
✓ 820 packages installed; agents re-enabled (claude-code, codex, gemini-cli)
✓ JetBrains Mono Nerd Font installed for proper glyph rendering (commit 030bea2)
✓ All functional commits on main (5270d12, 871c6d9, 8233240, 030bea2)
✓ Phone daily-usable; blog series unblocked

**Status:** Awaiting user push of `030bea2` if not yet done. Functional work complete.

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

---

## BACKLOG / DEFERRED

### Nix-on-Droid Blog Series (2026-08-03 — Functional Work Complete, Writing Deferred)

**Status:** Generation 4 functional and verified. Blog series now unblocked (no longer waiting for working system).

**Pending posts (user writing, low priority):**
- [ ] Write architecture post (portable layer, one-flake strategy, glibc pin)
- [ ] Write deployment post (phone setup, Makefile targets, adb debug channel)
- [ ] Write MCP integration post (phone-agent Termux shim, Tailscale)
- [ ] (Optional) Performance/runtime gotchas post
- [ ] (Optional) Troubleshooting recovery ladder post

**Waiting on:** User to write blog posts (lower priority than active work).
