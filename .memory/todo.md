---
type: todo
project: Vol NixOS
last_updated: 2026-08-03
status: active
---

# Open Tasks and Enhancement Roadmap (`memory/todo.md`)

---

## COMPLETE (2026-08-03)

### Nix-on-Droid — Generation 4 Live and Verified (2026-08-02 — VERIFIED WORKING 2026-08-03)

✓ glibc 2.42 TCGETS2 regression diagnosed and fixed via nixos-25.11 pin
✓ Generation 4 activation successful end-to-end
✓ Fish shell interactive on cold start
✓ Shared `home/common/` layer ported intact (zero changes)
✓ 820 packages installed; agents operational (claude-code, codex, opencode)
✓ JetBrains Mono Nerd Font installed for proper glyph rendering (commit 030bea2)
✓ claude-code full Ink/React TUI verified rendering on phone (critical test passed)
✓ **opencode 1.1.14 added** from nixos-25.11 (no backport needed; commit 34f3b20)
✓ Phone is now daily-usable; blog series unblocked

### Nix-on-Droid — Generation 5 Activated (2026-08-03 — VERIFIED LIVE)

✓ **proot unpack bug root cause identified and fixed** (2026-08-03, commit d4f2968): nixpkgs' `_defaultUnpack` uses `cp -pr` which fails under proot when chmod-ing directories it creates. Fix: pre-create destination, copy contents with `cp -r --no-preserve=mode,ownership $src/. $dest/`, then `chmod -R u+w $dest`. Also fixed cargo's vendor hook with `cargoVendorDir = "vendor"` to take the no-copy branch (required pairing).
✓ **rtk 0.44.0** built and verified on phone (native aarch64 build, links glibc-2.40-224)
✓ **mcp-gateway 3.3.2** built and verified on phone with borrowed rustc 1.97.0 from unstable (links glibc-2.40-224, zero glibc-2.42 in runtime)
✓ **termux-am** builds successfully with proot fix (unblocks android-integration)
✓ Both backports added to `droid/agents.nix` (commits d4f2968, 2654b2e)
✓ Phone native build proven faster than QEMU emulation — binfmt on volnix not needed
✓ prootUnpack mechanism documented as canonical solution for future phone builds
✓ Cold-start verification: tty, rtk, mcp-gateway, opencode, claude-code, codex all on PATH
✓ glibc-2.40-224 only in entire profile closure (zero glibc-2.42)

**Status:** Generation 5 activated and verified live. Phone daily-usable.

---

## IN PROGRESS / AWAITING USER DECISION

### Wire android-integration — Choose Strategy (2026-08-03 — USER DECISION PENDING)

**Status:** termux-am now builds successfully (proot unpack fix applied). Two approaches to integrate:

1. **disabledModules approach** (~60 lines): Disable upstream's `android-integration.nix`, ship patched copy with `prootUnpack` applied. Full feature set (termux-open-url, termux-wake-lock), but requires ongoing upstream drift tracking.

2. **xdg-open shim** (~5 lines): `writeShellScriptBin "xdg-open"` calling the built termux-am. Gets OAuth's browser opening; skips wake-lock and setup-storage.

**User decision needed:** Which approach (1 or 2)? Or defer android-integration entirely?

### Verify tether Compatibility with gemini-cli 0.25.2 (AWAITING USER DECISION)

**Status:** Decision point. gemini-cli 0.25.2 is present in nixos-25.11. antigravity-cli is absent (requires nixos-unstable).

**Question:** Does tether call antigravity-cli by name, or will it work with any gemini CLI? If tether works with 0.25.2, gemini on phone is free (already in 25.11).

**Steps (user decision first):**
- [ ] User clarifies: does tether require antigravity-cli specifically, or is gemini-cli 0.25.2 sufficient?
- [ ] If 0.25.2 works: add to `droid/agents.nix` (no backport needed)
- [ ] If antigravity-cli required: backport it (fourth Rust crate, but lower priority than rtk/mcp-gateway)

---

## BACKLOG / DEFERRED

### Noctalia Bar — Dual Wrap-Around Layout (2026-06-22 — LIVE, CAPTURE PENDING)

**Status:** Live and fully styled in runtime `~/.local/state/noctalia/settings.toml`, user-approved ("awesome"). **NOT yet committed to git.**

**Steps (in order, lower priority):**
- [ ] Capture runtime state to `dots/noctalia/config.toml`
- [ ] Commit Ayu Green color-engine theme (`dots/color-engine/themes/ayu_green.json`)
- [ ] Commit regenerated dotfiles (`dots/kitty/`, `dots/starship/starship.toml`)

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

### Nix-on-Droid Blog Series (2026-08-03 — Functional Work Complete, Writing Deferred)

**Status:** Generation 5 functional and verified. Blog series now unblocked (no longer waiting for working system).

**Pending posts (user writing, low priority):**
- [ ] Write architecture post (portable layer, one-flake strategy, glibc pin)
- [ ] Write deployment post (phone setup, Makefile targets, adb debug channel)
- [ ] Write MCP integration post (phone-agent Termux shim, Tailscale)
- [ ] Write proot portability post (one-line bug behind every directory-source build failure)
- [ ] (Optional) Performance/runtime gotchas post
- [ ] (Optional) Troubleshooting recovery ladder post

**Waiting on:** User to write blog posts (lower priority than active work).
