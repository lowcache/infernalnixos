---
type: todo
project: Vol NixOS
last_updated: 2026-08-02
status: active
---

# Open Tasks and Enhancement Roadmap (`memory/todo.md`)

---

## IN PROGRESS / AWAITING USER ACTION

### nix-on-droid Port & Blog Series (2026-08-02 — PROPOSED)

**Scope:** Create nix-on-droid support for Vol NixOS, port parts of volnixos to Android via nix-on-droid app, write blog post series documenting the process, explore morphoAgent MCP server cross-platform integration.

**Reference:** `nixos/phone-agent/` directory contains existing Termux + Shizuku setup documentation.

**Architectural choice (PENDING DECISION):** Separate flake (independent versioning, cleaner publishing, easier to showcase as standalone project) vs. integrated output in current flake (simpler repo structure, shared dependencies). **Once decided, add to decisions.md as Decision #31.**

**Investigation steps:**
- [ ] Decide architectural approach (separate flake vs. output) — consider blog audience expectations, versioning story, reusability
- [ ] Review `nixos/phone-agent/README.md` and existing Termux/Shizuku infrastructure
- [ ] Define MVP scope for v1 (minimal viable nix-on-droid config; what's the blog post's focus?)
- [ ] Assess morphoAgent MCP server porting requirements (already running on S26 Ultra?)
- [ ] Sketch blog post outline (audience, scope, technical depth, narrative arc)
- [ ] Implement chosen architecture (flake structure, module organization, CI/build)
- [ ] Test on real nix-on-droid install

---

### Noctalia Bar — Dual Wrap-Around Layout (2026-06-22 — LIVE, CAPTURE PENDING)

**Status:** Live and fully styled in runtime `~/.local/state/noctalia/settings.toml`, user-approved ("awesome"). **NOT yet committed to git.**

**Steps (in order):**
- [ ] Capture runtime state to `dots/noctalia/config.toml`
- [ ] Commit Ayu Green color-engine theme (`dots/color-engine/themes/ayu_green.json`)
- [ ] Commit regenerated dotfiles (`dots/kitty/`, `dots/starship/starship.toml`)

**Lower priority than convention alignment work.**

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

## COMPLETED & ARCHIVED

(See archive_entries for long list of completed phases and tasks)
