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
✓ **android-integration fully investigated**: two attempted fixes failed; documented as closed (commits 34f3b20, 03f3a02)
✓ All functional commits pushed to main
✓ Phone is now daily-usable; blog series unblocked

**Status:** Ready for next phase: rtk + mcp-gateway backports (phone-first Rust build). Awaiting tether/gemini-cli compatibility decision.

---

## IN PROGRESS / AWAITING USER ACTION

### Backport rtk and mcp-gateway to nixos-25.11 — Phone-First Native Build

**Status:** Queued. Both are Rust packages (`cargoDeps`); phone is 8-core native at 4.74 GHz (faster than QEMU emulation on volnix). Test phone build first, fall back to binfmt+nix-copy if needed.

**Steps (in order):**
- [ ] Build rtk 0.44.0 on phone (native `nix build …` against 25.11 nixpkgs)
- [ ] If successful: backport expression (`callPackage` unstable's package.nix against 25.11's pkgs) and add to `droid/agents.nix`
- [ ] Build mcp-gateway 3.3.2 on phone (same approach)
- [ ] If either fails: set up binfmt on volnix (`boot.binfmt.emulatedSystems = [ "aarch64-linux" ]`) and retry via `nix copy`
- [ ] Activate generation on phone; verify both work

**Rationale:** Native beats emulated 5–10×; two small crates may finish faster on-device than setting up cross-compile. If phone build fails, binfmt is a one-line fix.

### Verify tether Compatibility with gemini-cli 0.25.2 (Blocker for gemini Decision)

**Status:** Decision point. Awaiting user input.

**Context:** User moved from gemini-cli to antigravity-cli; antigravity-cli is absent from nixos-25.11. gemini-cli 0.25.2 IS present in 25.11. Question: does tether need antigravity-cli specifically, or will it work with gemini-cli 0.25.2?

**Steps:**
- [ ] User decides: does tether call antigravity-cli by name, or just "any gemini CLI"?
- [ ] If tether works with 0.25.2: gemini on phone is free (already in 25.11). Add to `droid/agents.nix`.
- [ ] If tether requires antigravity-cli: backport it (third Rust crate, but lower priority than rtk/mcp-gateway).

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
