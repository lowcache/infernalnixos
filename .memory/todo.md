---
type: todo
project: Vol NixOS
last_updated: 2026-07-14
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

### Krita G'MIC Plugin Crash Fix — Verification Complete (2026-07-14 — VERIFIED WORKING)

**Status (2026-07-14 — COMPLETED):** Root cause identified and fixed; full system build verified; user tested and confirmed fix working.

**What was done:**
- ✅ Identified root cause: `GmicQt::FiltersView::onCustomContextMenu` calls `QObject::deleteLater()` on nullptr context-menu pointers (constructor leaves them as nullptr, first right-click/stylus-press in filter tree crashes)
- ✅ Generated patch: `overrides/gmic-qt-filtersview-nullptr-contextmenu.patch` (null guards around both `deleteLater()` calls)
- ✅ Attempted first wiring: `home/pkgs.nix` added standalone `krita-plugin-gmic-patched` entry (FAILED: buildEnv conflict, duplicate `krita_gmic_qt.so`)
- ✅ Corrected wiring: override plugin inside wrapper via `pkgs.krita.override { krita-plugin-gmic = krita-plugin-gmic-patched; }` (removes duplicate, single patched copy bundled)
- ✅ Full system build completed exit 0; user-environment built with no conflicts
- ✅ Applied via `make switch` 2026-07-14
- ✅ User tested: right-clicked in G'MIC filter tree — context menu opens without crash ✓

**Note:** Earlier June crashes had different signals (SIGBUS/SIGABRT); those may be separate. If crashes continue after this fix, pull new backtrace for separate investigation. Uncommitted changes in working tree; user decision on commit pending.

### Phase 3 — Username Parameterization + Storage Mount Label (2026-07-09 — COMPLETE & COMMITTED)

**Status:** Both tasks completed and committed.
- ✅ **P3-T1** (`b780fdc`) — Username parameterized via `flake.nix` let binding; all occurrences in nixos/* and hardware-configuration.nix now derive from `${username}`. Toplevel drvPath byte-identical at current value.
- ✅ **P3-T2** (`170eaba`) — Storage mount switched from UUID to `/dev/disk/by-label/STORAGE` (label already present); UUID preserved in recovery comment. Next switch safe with no disk operation.

### Phase 4 — Sops File Scoping + Secrets Split (2026-07-09 — COMPLETE & COMMITTED)

**Status:** Three tasks completed and committed.
- ✅ **P4-T1** (`3d99065`) — `.sops.yaml` creation rules scoped: `host-secrets.yaml` (user+host), `vm-secrets.yaml` (host only), legacy rule last. YAML validated with `yq`.
- ✅ **P4-T2** (`9c6b437`) — `git mv secrets.yaml host-secrets.yaml`; created `vm-secrets.yaml` non-interactively with placeholder. Verified recipient count (2 vs 1).
- ✅ **P4-T3** (`0b3111c`) — host `defaultSopsFile` → `./host-secrets.yaml`; net-gate VM → `./vm-secrets.yaml`. `nix flake check` passes.

### Phase 5 — Tor SOCKS5 + UID Routing + Wrappers + anonymous.target (2026-07-09 — COMPLETE & COMMITTED)

**Status:** Five tasks completed and committed.
- ✅ **P5-T1** (`a9b7fa2` + `ca5884d`) — net-gate: added SOCKSPort 9050, opened firewall TCP 9050. Host: anon-user (UID 10000), iptables mangle rules, anon-routing service (on-demand). Casing fix: `SocksPort` → `SOCKSPort` (nixpkgs module key).
- ✅ **P5-T2** (`290290d`) — Four wrapper scripts: `tor-brave`, `tor-curl`, `tor-check`, `anon-run`. All build successfully; bash syntax validated. VM IP in single `let` binding.
- ✅ **P5-T3** (`2a4f101` + `ca5884d`) — `anonymous.target` (manual-only, no boot autostart); `anon-routing` `partOf anonymous.target`; `anon-socks-check` gate; fish `anon-on`/`anon-off` abbreviations added.

### Phase 6 (Partial) — Explanatory Comments (2026-07-09 — P6-T1 COMPLETE)

**Status (2026-07-09):** Comments added to kernel.nix; remaining files pending.
- ✅ **P6-T1 (partial)** — Added comments to `nixos/hardware/asus-ryzen-nvidia/kernel.nix`:
  - Line ~28: "Disable deep C-states for lower wakeup latency" for `processor.max_cstate=1`
  - Line ~38: "Prevents mmap exhaustion in resource-heavy apps" for `vm.max_map_count`
  - Line ~39: "Paired with zramSwap to accelerate large-memory workloads" for `vm.swappiness`
- ⏳ **P6-T1 (remaining):** Comments still pending for `nixos/configuration.nix` and `nixos/hardware-configuration.nix` (noted in session but not yet applied).

### Git Safe Directory Whitelist (2026-07-06 — VERIFICATION COMPLETE)

**Status (2026-07-09):** Applied, verified, live.
- ✅ `programs.git.config.safe.directory` entries added to `nixos/configuration.nix:159` (`/persist/home/lowcache/.nix-config` and `/home/lowcache/.nix-config`).
- ✅ `nix eval` confirmed entries land in generated `/etc/gitconfig`.
- ✅ `make switch` executed; `/etc/gitconfig` now whitelists both paths.
- ✅ `make switch-detached` now works without "exit 254" error.

### Nix Consolidation + Rebuild Verification (2026-06-28 — COMPLETE & REBOOTED)

**Status (2026-07-09):** User rebooted after 2026-06-28 switch; new config loaded.
- ✅ `make switch` completed; noctalia binary installed and verified.
- ✅ User confirmed reboot successful; system in stable state.
- ✅ No regressions reported post-reboot.

### Hyprland + ii/quickshell Removal (2026-06-28 — COMPLETE & COMMITTED)

**Status:** Fully decoupled, deleted, and docs updated. Committed as `ee2efb4`.
- ✅ All cross-references removed/updated.
- ✅ Docs updated, `mkdocs build --strict` passes.

### limbo Profile Removal (2026-06-28 — COMPLETE & COMMITTED)

**Status:** Fully excised and portfolio reframed. Committed as `650fbde`.
- ✅ `nixosConfigurations.limbo` removed.
- ✅ Docs reframed from "portable reference" to "portfolio, not a distro".

### memd Graduation (2026-06-25–2026-07-09 — PHASE 1–3 COMPLETE & LIVE)

**Status:** Standalone repo + home-manager module integration complete.
- ✅ Phase 1 & 2 done; memd operational from new home.
- ✅ Phase 3 done; integrated as HM module with flake input and home/default.nix config. Sweep timer and Claude Code hooks managed by home-manager. Canonical final form. Live and verified 2026-07-09.

### tether Graduation (2026-06-27 — COMPLETE & LIVE)

**Status:** Moved to `~/CodeRepo/tether` (standalone repo, GitHub remote ready).
- ✅ Smoke-tested; symlinks live.

### Documentation Alignment (2026-07-09 — COMPLETE & VERIFIED)

**Status:** All docs files audited and updated to match live config.
- ✅ Three parallel tether audits (architecture, desktop, tooling).
- ✅ All findings verified against source and applied.
- ✅ `mkdocs build --strict` passes; site regenerated.
- ✅ `android-vm.nix` deliberately left undocumented (not imported).

### Convention Alignment — NixOS Best Practices (2026-07-12 — COMPLETE & COMMITTED)

**Status:** All five convention alignment tasks completed and verified.
- ✅ **P7-T1** (formatter + RFC 166 nixfmt adoption) — `flake.nix` exposes `formatter.x86_64-linux = nixfmt-tree`; repo reformatted to RFC 166 style (15 files, ~750 LOC). `nix fmt` now works and matches nixpkgs-official standard.
- ✅ **P7-T2** (android-vm.nix repairs) — Parse fixed (removed trailing commas, escaped shell params, merged duplicates); lints clean (statix, deadnix, nixfmt all pass). WIP eval-level bugs noted in memd inbox for when file is activated.
- ✅ **P7-T3** (lint gates via flake check) — Added `checks.x86_64-linux.{formatting,lint}` outputs; `nix flake check` exits 0. Coverage: nixfmt --check, statix, deadnix over flake source. `statix.toml` ignores `dots/**`.
- ✅ **P7-T4** (deadnix cleanup) — Removed unused lambda patterns from flake destructuring; merged duplicate `home-manager.*` keys and three `xdg` blocks; converted two `x = x;` to `inherit`.
- ✅ **P7-T5** (redundancy removal) — Dropped `nix.settings.auto-optimise-store` (kept `nix.optimise.automatic` for same effect); removed duplicate `nvd`.

---

## CRITICAL BLOCKERS

* [ ] **Rotate OAuth tokens (Google/Gemini):** Exposed in commit `2ccdd52` (2026-06-09). History scrub required (`git filter-repo --invert-paths` + `git push --force` after rotation). See mistakes.md #8. **This is separate from the current work; lower priority but still open.**

---

## Known Issues & Follow-Ups

* **VM secrets isolation (future):** VM can still decrypt host-secrets via mounted nix store + host SSH key in `/persist`. Full isolation requires VM to have its own SSH key and host key dropped from VM share. Threat model scoping is correct; isolation upgrade deferred.
* **Portal FileChooser:** Fixed 2026-06-19 (routing to gtk backend, durable in home config). Verify post-reboot.
* **Playwright gateway restart:** Run `gateway_kill_server + gateway_revive_server` (reload insufficient).
* **Debt-harvest skill** (`/debt`): Live at `~/.claude/skills/debt/SKILL.md`, on-demand. Greps `[CEILING]:` markers across repo, writes to `.memory/inbox/` for curator to fold into todo/debt tracking.
* **Tether operating lesson:** Pipe source content inline instead of making worker read files via tools — eliminates timeouts, ensures fast completion (proven: 52s vs 330s+ timeout).
* **Krita G'MIC patch local fix:** Once nixpkgs ships a fixed gmic-qt (upstream bugfix likely in future release), remove `overrides/gmic-qt-filtersview-nullptr-contextmenu.patch` and revert `home/pkgs.nix` back to vanilla `krita-plugin-gmic` (no override).
