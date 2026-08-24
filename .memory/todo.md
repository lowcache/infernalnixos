---
type: todo
project: Vol NixOS
last_updated: 2026-08-24
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

### Krita SVG Text Engine — Verified Fixed on 6.0.2.1 (2026-08-24)

✓ Verified (2026-08-24): SVG text engine works on Krita 6.0.2.1; FreeType glyph crash from 6.0.1 is fixed
✓ 5 font families tested; zero render errors, no crashes, empirical evidence captured
✓ Rasterize-to-paint-layer workaround now obsolete

### Krita Font Gallery Plugin — Refactor to Native SVG Shapes (2026-08-24)

✓ Refactored `_insert_sample` to insert native editable SVG text shapes via `createVectorLayer() + addShapesFromSvg()`
✓ Replaced QPainter/QImage/`setPixelData` rasterize path with pure `build_text_svg()` function (independently testable)
✓ XML escaping verified (metacharacters render literally; space entities used for whitespace)
✓ Multi-line text verified (one `<tspan>` per line; vertical advance correct)
✓ End-to-end tested in isolated harness (`<scratchpad>/ktest/`, Xvfb-driven Krita 6.0.2.1); 4/4 cases pass
✓ Krita swap file moved from `/tmp` (4 GB tmpfs) to `~/Storage/tmp/krita-swap` (269 GB NVMe, 2026-08-24) to prevent SIGBUS crashes
- [ ] Interactive on-canvas text tool (GUI, not engine) — human verification pending (~10 min)

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

### Wiki — Hugo Activation Complete, SEO Fixes Live, CI & Polish Pending (2026-08-15, updated 2026-08-23)

- [x] Migrate MkDocs → Hugo (27 pages, 2026-08-15)
- [x] Deploy to independent repo `lowcache/volnixos-wiki`
- [x] Fix `layouts/robots.txt` override blocking Bing/DuckDuckGo (2026-08-23, see mistakes.md)
- [x] Submit wiki sitemap to GSC — never submitted before; 30/30 discovered same day (2026-08-23)
- [x] Refresh stale blog sitemap in GSC — 39 → 50 discovered (2026-08-23)
- [x] Place first two inbound links to the wiki: NixOS Wiki `Noctalia_Shell` page (Configuration section sourced to upstream `home-module.nix`, plus See also) and nix-on-droid issue #480 comment (2026-08-23)
- [ ] Connect Workers Builds CI (set command `./build.sh`, var `HUGO_VERSION=0.164.0`)
- [ ] Convert home page to native data-driven layout (currently markdown, should be hero/card-grid yaml)
- [ ] Visual overhaul: port Material palette to E25DX, center content (currently left-aligned)
- [ ] Re-check GSC Page Indexing report ~2026-08-30: confirm whether the 40 "Crawled – currently not indexed" URLs (spiked 2026-08-17, post MkDocs→Hugo port) are draining out — recovery signal, not yet confirmed
- [ ] If the nix-on-droid #480 reporter confirms the same proot `_defaultUnpack` bug as `.nix-config`'s fix, open an upstream PR contributing `prootUnpack` (decisions.md #32) rather than leaving it as a local backport

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
