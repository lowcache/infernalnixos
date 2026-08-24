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

### Wiki Documentation — Krita Page Published (2026-08-24)

✓ Published `content/en/desktop/krita.md` (weight 40) to volnixos-wiki
✓ Updated desktop section index to link the new page
✓ Covered: swap hazard + fix, text engine timeline, plugin refactoring, G'MIC patch, testing harness
✓ Build clean: 31 pages, 47 internal links validated

---

## IN PROGRESS / AWAITING ACTION

### Krita Swap Directory Persistence (2026-08-24 — IMPLEMENTATION STAGED, ACTIVATION PENDING)

The swap directory `~/Storage/tmp/krita-swap` prevents SIGBUS crashes from mmap-based caching on tmpfs (mistakes.md #13). Implementation was staged 2026-08-24 but not yet activated.

- [x] Declare swap directory durability via activation script: added `$HOME/Storage/tmp/krita-swap` to `home.activation.ensureScratchDirs` in `home/default.nix` with explanatory comment (2026-08-24)
- [ ] Run `make switch` to activate the declaration
- [ ] Verify swap location still resolves post-rebuild and Krita renders without SIGBUS (batched with other pending changes)

**Note:** Implementation chose activation script over impermanence bind-mount because swap is temporary, unbounded-growth, and session-specific (not durable). The directory must simply exist on persistent backing storage, not be transactionally bound. See decisions.md #36 for persistence strategy rationale.

### Thunderbird + Spotify Persistence (2026-08-24 — IMPLEMENTATION STAGED, ACTIVATION PENDING)

Thunderbird and Spotify config/state were not persisted across tmpfs-root wipe. Both apps came up factory-new after reboot. Implementation was staged 2026-08-24 but not yet activated.

- [x] Implement Spotify config persistence: added `".config/spotify"` to impermanence bind-mount list in `home/persist.nix` (2026-08-24)
- [x] Pre-seed persisted state: copied live `~/.config/spotify` into `/persist/home/lowcache/.config/spotify` from tmpfs while Spotify not running (2026-08-24)
- [x] Implement Thunderbird persistence: created symlink target `~/Storage/thunderbird` and `home.file` mkOutOfStoreSymlink in `home/persist.nix` (2026-08-24)
- [x] Pre-create symlink target: added `$HOME/Storage/thunderbird` to `home.activation.ensureScratchDirs` (2026-08-24)
- [ ] Run `make switch` to activate both declarations (batched with other pending changes)
- [ ] Verify post-switch: Spotify stays logged in across reboot; Thunderbird profile persists; no activation collisions

**Persistence split rationale (decisions.md #36):** Spotify uses impermanence (bounded 32 KB config), Thunderbird uses Storage symlink (unbounded mail stores + caches). The split prevents mount/symlink collisions that would cause silent shadowing.

### Phone-Agent MCP Activation (2026-08-07 — Claude Code Restart Pending)

**Status:** Phone-agent wired to Claude Code via HTTP (`.model/.claude/.mcp.json`). Token exported from sops secrets in `home/shell.nix`. Configuration ready. **`make switch` completed 2026-08-21.** MCP server is now running and should be accessible; Claude Code session must be restarted to connect.

- [x] Run `make switch` to activate phone-agent MCP in Claude Code (completed 2026-08-21)
- [ ] Restart Claude Code session (MCP servers read at session startup)
- [ ] Verify phone-agent tools are accessible (should appear in MCP list)

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

### MCP Server Evaluation — Cloudflare Official Tier + Third-Party Triage (2026-08-24 — Survey Complete)

**Status:** MCP server landscape surveyed via tether (198 lines at `scratchpad/mcp-survey.md`). Results categorized and prioritized.

**Findings:**
- **Tier 1 (Cloudflare official, recommended):** 12 servers (Workers Builds, Observability, GraphQL, DNS Analytics, Cloudflare API, Docs, Radar, Browser Run, Logpush, Audit Logs, AI Gateway, Bindings). All require `http_url:` / `streamable_http:` config in gateway.yaml (not `command:`, since these are remote stdio endpoints). Workers Builds connects directly to your open CI todo.
- **Tier 2 (SEO, third-party OAuth-required):** GSC (7 implementations; recommend safe MIT read-only version), GA4, Bing. Require OAuth grant to your Search Console + analytics accounts.
- **Tier 3 (Other high-value third-party):** Sentry (official remote, free with account), Stripe (official, monetization-coupled), CVE MCP (free, NVD+CISA+GitHub Advisories, local uvx), SAST MCP (local Semgrep/Bandit/Trivy wrapper).

**Caution:** Survey lists Postgres as "Official + Active" in upstream servers repo; this is likely stale (most reference servers were archived). Verify before using.

**Security constraint:** Each MCP server credential grant expands trust surface. MCPS Audit ([razashariff/mcps-audit](https://github.com/razashariff/mcps-audit)) scans MCP configs against OWASP MCP Top 10. Before expanding beyond current 8 backends, run audit on `.model/.claude/.mcp.json` + `gateway.yaml`.

**Next steps:**
- [ ] Run MCPS Audit on existing 8 backends; resolve any medium/high findings before expansion
- [ ] Prioritize Cloudflare Workers Builds + Observability (aligns with wiki/deployment CI todo)
- [ ] Conditional: Activate Sentry (free, error/trace querying) + CVE MCP (security scanning)
- [ ] Defer: Stripe MCP (monetization not yet live), full GSC/GA4 suite (lower priority than core tooling)
- [ ] Archive `scratchpad/mcp-survey.md` post-implementation (reference only, not durable)

### Wiki — Polish and CI Integration (2026-08-15, partially done)

- [ ] Connect Workers Builds CI (set command `./build.sh`, var `HUGO_VERSION=0.164.0`)
- [ ] Convert home page to native data-driven layout (currently markdown, should be hero/card-grid yaml)
- [ ] Visual overhaul: port Material palette to E25DX, center content (currently left-aligned)
- [ ] Re-check GSC Page Indexing report ~2026-08-30: confirm whether the 40 "Crawled – currently not indexed" URLs (spiked 2026-08-17, post MkDocs→Hugo port) are draining out — recovery signal, not yet confirmed
- [ ] If the nix-on-droid #480 reporter confirms the same proot `_defaultUnpack` bug, open an upstream PR contributing `prootUnpack` (decisions.md #32) rather than leaving it as a local backport

### Noctalia Bar — Dual Wrap-Around Layout (2026-06-22 — LIVE, CAPTURE PENDING)

- [ ] Capture runtime state to `dots/noctalia/config.toml`
- [ ] Commit Ayu Green color-engine theme
- [ ] Commit regenerated dotfiles

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

### Blog Post: "The workaround that outlived its bug" (Krita post — Outline Ready 2026-08-24)

**Status:** Outline complete at `volnixos-blog/content/posts/drafts/krita-on-a-volatile-root.md` with `draft: true`. Comprehensive beat structure, verified citations, angle: one story covering both the swap SIGBUS hazard and the philosophical cost of undeclared state on an impermanence system.

- [ ] Write full body (user authoring)
- [ ] Cross-check cited numbers against decisions.md #21, mistakes.md 2026-08-24, state.md §9 (Krita section)
- [ ] Publish (remove `draft: true`, then `cd volnixos-blog && make build && make deploy`)
