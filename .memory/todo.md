---
type: todo
project: Vol NixOS
last_updated: 2026-08-21
status: active
---

# Open Tasks and Enhancement Roadmap (`memory/todo.md`)

---

## COMPLETE

### Nix-on-Droid — Generation 5 Activated (2026-08-03)

✓ proot unpack bug fixed (2026-08-03, commit d4f2968)
✓ rtk 0.44.0, mcp-gateway 3.3.2, termux-am built natively on phone
✓ glibc-2.40-224 only in entire profile closure (zero glibc-2.42)
✓ Phone daily-usable; blog series unblocked

### Waydroid Setup — Move Images to Persistent Storage (2026-08-21)

✓ Ran move-waydroid.sh script; `/persist/var/lib/waydroid` contains system images
✓ Ran `make switch` to activate system persistence binds and home-manager symlinks
✓ tmpfs root decreased from 100% → 3% (99 M / 4.0 G); `/persist` usage at 46% (140 G free)
✓ `~/Android` and `~/.android` symlinks on Storage remain accessible and working
✓ GAPPS images downloaded and initialized (system.img 2462.4 M, vendor.img 535.5 M)
✓ Android session RUNNING, container RUNNING, DHCP lease obtained (IP 192.168.240.112)
✓ Device registered for Play Store certification (Android ID retrieved and registered at google.com/android/uncertified)
✓ Certification propagation in progress; awaiting Play Store sign-in verification

---

## IN PROGRESS / AWAITING USER DECISION

### Phone-Agent MCP Activation (2026-08-07 — Claude Code Restart Pending)

**Status:** Phone-agent wired to Claude Code via HTTP (`.model/.claude/.mcp.json`). Token exported from sops secrets in `home/shell.nix`. Configuration ready. **`make switch` completed 2026-08-21.** MCP server is now running and should be accessible; Claude Code session must be restarted to connect.

- [x] Run `make switch` to activate phone-agent MCP in Claude Code (completed 2026-08-21)
- [ ] Restart Claude Code session (MCP servers read at session startup)
- [ ] Verify phone-agent tools are accessible (should appear in MCP list)
- [ ] (Optional) Clean up or drop `nixos/phone-agent/mcp-gateway.nix` (example uses outdated schema; gateway route failed auth test)

### Wire android-integration — Choose Strategy (2026-08-03 — USER DECISION PENDING)

**Status:** termux-am builds successfully. Two approaches:

1. **disabledModules approach** (~60 lines): Full feature set (termux-open-url, termux-wake-lock), but track upstream drift.
2. **xdg-open shim** (~5 lines): Gets OAuth's browser opening; skips wake-lock and setup-storage.

**User decision needed:** Which approach (1 or 2)? Or defer entirely?

### Verify tether × gemini-cli 0.25.2 (AWAITING USER DECISION)

**Question:** Does tether require antigravity-cli specifically, or will gemini-cli 0.25.2 (nixos-25.11) suffice?

- [ ] User clarifies antigravity vs 0.25.2
- [ ] If 0.25.2 works: add to `droid/agents.nix` (no backport)
- [ ] If antigravity required: backport (lower priority than rtk/mcp-gateway)

---

## BACKLOG / DEFERRED

### Wiki — Hugo Activation Complete, CI & Polish Pending (2026-08-15)

- [x] Migrate MkDocs → Hugo (27 pages, 2026-08-15)
- [x] Deploy to independent repo `lowcache/volnixos-wiki`
- [ ] Connect Workers Builds CI (set command `./build.sh`, var `HUGO_VERSION=0.164.0`)
- [ ] Convert home page to native data-driven layout (currently markdown, should be hero/card-grid yaml)
- [ ] Visual overhaul: port Material palette to E25DX, center content (currently left-aligned)

### Noctalia Bar — Dual Wrap-Around Layout (2026-06-22 — LIVE, CAPTURE PENDING)

- [ ] Capture runtime state to `dots/noctalia/config.toml`
- [ ] Commit Ayu Green color-engine theme
- [ ] Commit regenerated dotfiles

### Windows 11 VM — Installation In Progress

- [ ] Verify VM accessible post-reboot (2026-07-09)
- [ ] Complete OOBE (network/account setup)
- [ ] Reach Windows desktop; verify graphics/audio/network

### XWayland Satellite Startup — Permanent niri Integration (2026-06-23)

- [ ] Add `spawn-at-startup "xwayland-satellite" ":0"` to `dots/niri/config.kdl`
- [ ] Test: launch FireAlpaca without manual `:0` start

### Krita 6.0.1 Font Gallery Plugin — End-to-End Test (2026-06-22)

- [ ] Restart Nix Krita cleanly
- [ ] Type text in Font Gallery docker input box
- [ ] Double-click font; verify no crash and raster layer appears

### SessionEnd Hook — Work-Routing (2026-06-18)

- [ ] Code path-prefix routing logic (dots/ → dots inbox, else → root)
- [ ] Register hook in `~/.claude/settings.json` as SessionEnd event
- [ ] Test with dummy work note

### Nix-on-Droid Blog Series (2026-08-03 — Functional Work Complete)

**Pending posts (user writing, lower priority):**
- [ ] Architecture post (portable layer, one-flake strategy, glibc pin)
- [ ] Deployment post (phone setup, Makefile targets, adb debug channel)
- [ ] MCP integration post (phone-agent Termux shim, Tailscale)
- [ ] proot portability post (chmod denial & structural sandbox fix)
- [ ] (Optional) Performance/runtime gotchas, troubleshooting recovery ladder
