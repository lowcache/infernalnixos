---
type: state
project: Vol NixOS
last_updated: 2026-08-02
status: active
---

# System State Inventory (`memory/state.md`)

This file is the single source of truth for the active configuration, mapping, and hardware state of **Vol NixOS**.

---

## 1. System & Hardware Profile

* **Hostname:** `volnix` | **OS:** NixOS 26.11 (Zokor) | **Shell:** Fish (HM)
* **Current generation:** system-221 (`/nix/store/a18ffz3c…-nixos-system-volnix-26.11.20260726.624af66`)
* **Desktop:** niri (Wayland, sole WM, default session) + Noctalia v5 (C++ shell)
* **Display:** Wayland native; XWayland via `xwayland-satellite` (`:0`, for xcb-only AppImages and Flatpak Qt5 apps; permanent startup pending).
* **GPU:** Hybrid AMD HawkPoint2 iGPU + NVIDIA RTX 4050 Mobile dGPU.
* **Audio (2026-06-16):** NVIDIA HDMI (card 0), AMD HDMI (card 1), Realtek ALC256 (card 2, `66:00.6`). Default sink: Realtek ALC256 (wpctl #58), profile `output:analog-stereo+input:analog-stereo`, 70% unmuted, analog speakers. HDMI cards on `pro-audio` (switch to "Digital Stereo" if HDMI audio needed).
* **Input Devices (2026-07-13):** Vial keyboard configured for unprivileged hidraw access via udev rule in `nixos/configuration.nix:services.udev.extraRules`. Rule matches serial `*vial:f64c2b3c*` with MODE=0660, GROUP=users, TAG+="uaccess". Pending rebuild application; activate via replug or `sudo udevadm control --reload && sudo udevadm trigger`.

---

## 2. Impermanence & Persistence Mappings

Ephemeral root (`tmpfs`, ~4 GB, wiped on boot). Permanent data on `/persist`.

**User dotfiles (`~/.nix-config/dots/`):** `niri`, `noctalia`, `quickshell`, `kitty`, `cava`, `fuzzel`, `wlogout`, `starship.toml`, `color-engine`.

**Persisted home directories (not repo-tracked):** `~/.codex`, `~/.gemini` (Gemini/Antigravity agent state; moved from `dots/gemini` to persisted real directory via home-manager impermanence 2026-07-24).

**Krita:** Native `~/.config/kritarc`, `~/.config/kritadisplayrc`, `~/.local/share/krita` → `~/Storage/krita-master/`. Pykrita plugins live at `~/Storage/krita-master/krita/pykrita/`.

**AI outputs:** `~/Pictures/fromAi/outputs` → `~/Storage/ai-generation/fooocus/outputs`.

**Imperative nix-env profiles (2026-07-27):** `~/.local/state/nix/profiles` persisted to `persist.nix` (canonical store where `nix-env -iA nixos.<pkg>` writes `profile-N-link` + `channels` generation + manifest). This allows session-scoped binary installs to survive the tmpfs wipe. The compat symlink `~/.nix-profile → ~/.local/state/nix/profiles/profile` is recreated declaratively via `home.file` with `force = true` at each activation, ensuring `~/.nix-profile/bin` hits PATH immediately after boot without needing a prior nix command. Caveat: `nix-env -iA nixos.*` requires the `nixos` channel; since `channels` generation is persisted alongside profiles, it should carry over — confirm `nix-channel --list` post-boot if installs can't resolve the channel.

**Cache enforcement (active 2026-06-17):** `xdg.cacheHome = "$HOME/Storage/.cache"`; `TMPDIR`, `PIP_CACHE_DIR`, `CLAUDE_CODE_TMPDIR` → `~/Storage/tmp`. `.cache/llmfit`, `.cache/noctalia` persisted.

**Quarantined fonts (2026-06-21):** Corrupt font `NoracleNerdFont-Regular.otf` (truncated cmap/OS/2 tables, crashed Krita 6.0.1 text tool) moved to `~/Storage/tmp/quarantined-fonts/`. `fc-cache -f` rebuilt.

**Flatpak data (persisted 2026-06-22):** `/var/lib/flatpak` and `~/.local/share/flatpak` persisted (`hardware-configuration.nix:91`, `persist.nix:110`); Flatpak installs survive boot. Flathub remote added; `org.kde.krita` 5.3.2.1 (uninstalled 2026-06-22) and `org.gimp.GIMP` 3.2.4 installed. Host fonts (`~/.local/share/fonts`, 2772 files) mounted read-only into Flatpak sandboxes; access via `filesystems=host`.

---

## 3. MicroVM Guest Network

* `net-gate`: host `vm-netgate` → `192.168.100.1`; guest → `192.168.100.2`; Tor `9040`/DNS `5353`/**SOCKS 9050 (2026-07-09)**.
* `tailscale-vm`: host `vm-tailscale` → `192.168.101.1`; guest → `192.168.101.2`.
* VM tap interfaces `unmanaged` in NetworkManager.

---

## 4. Active Workarounds

* **`make switch-detached` PATH Fix (2026-07-28 — FIXED):** Transient systemd units inherit minimal DefaultEnvironment PATH (dosfstools/mtools/e2fsprogs/util-linux/systemd only; no `git`). When lix's flake fetcher tried to exec `git` for input fetch, it failed silently with "exit code 254" (spawn error). Fix: Makefile target now passes `--setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin` to `systemd-run`, providing git and system binaries to the unit. Verified end-to-end 2026-07-28.

* **Krita 6.0.1 G'MIC Plugin Null-Pointer Crash (2026-07-14 — VERIFIED WORKING):** G'MIC-Qt filter tree was segfaulting on first right-click or stylus long-press in the filter list. Root cause: `GmicQt::FiltersView::onCustomContextMenu` calls `QObject::deleteLater()` on context-menu pointers the constructor left as `nullptr` — any context-menu event triggered the crash. Bug present in vanyossi/gmic v3.7.4.1 (upstream still has it as of 2026-07-14). **Fix applied and verified 2026-07-14:** `overrides/gmic-qt-filtersview-nullptr-contextmenu.patch` (null guards around both `deleteLater()` calls); `home/pkgs.nix` defines `krita-plugin-gmic-patched` with the patch applied, and `krita-wrapped` overrides `pkgs.krita` to bundle the patched gmic (override inside wrapper to avoid buildEnv conflicts). Build completed successfully; user tested right-click context menu — opens without crash. Patch verified working.

* **Ollama Pinned to 0.31.1 (2026-07-28):** `nixos/overlays/ollama.nix` pins `ollama-cuda` to pre-update nixpkgs rev `d407951` (evaluates to exact `/nix/store/yglxp77…-ollama-0.31.1` currently running) via `builtins.fetchTarball`. Upstream 0.32.3 fails to build on current nixpkgs: setup-cuda-hook exports `CUDAToolkit_ROOT` as semicolon-joined lib list (cudart/cublas/cccl), omitting nvcc; 0.32.3's new llama.cpp configure step trusts that env var, finds no nvcc, aborts with "CUDA Toolkit not found" at ggml-cuda/CMakeLists.txt:268 (~40 min into compile). Overlay avoids 40-minute rebuilds with zero behavior change. Revert condition: retry 0.32.x+ on next flake update.

* **Flake-Update Regression: pandas-stubs & niri (2026-07-28 — OVERLAYS IN PLACE):** `nix flake update` exposed two independent build failures. (1) `python3.14-pandas-stubs` 3.0.3 fails check phase: pytest >= 9.1.1 promotes `PytestRemovedIn10Warning` to hard error at collection; package sets `filterwarnings=error` in pyproject.toml, so all 8 collection errors abort the build. Transitive dep of `markitdown`/`pdfplumber` in HM path. Fix: `nixos/overlays/pandas-stubs.nix` downgrades warning via `PYTEST_ADDOPTS="-W ignore::pytest.PytestRemovedIn10Warning"` override; suite now passes (3151 passed, 5 skipped). (2) `niri 26.04` fails to build: vendor crate `libdisplay-info-sys 0.3.0` caps C library at `< 0.4.0`; this nixpkgs commit bumped `libdisplay-info` to 0.4.0, causing CMake to reject it ("Requested 'libdisplay-info < 0.4.0' but version of libdisplay-info is 0.4.0"). Fix: `nixos/overlays/niri.nix` pins `libdisplay-info 0.3.0` for niri (cache hit from cache.nixos.org, no rebuild). Both overlays verified working 2026-07-28. Revert conditions in overlay headers for each future flake update.

* **Krita 6.0.1 (2026-06-22):** Font Gallery pykrita plugin uses Qt rasterization (SVG text crashed err=84). With user-text input, multi-line rendering validated standalone; layer insertion proven. Pending: restart Nix Krita, type text, double-click font, verify no crash and raster layer appears.

* **Krita dual installation (2026-06-22):** Nix Krita only; Flatpak uninstalled (crashed SIGABRT on launch, created confusion).

* **XWayland (2026-06-23):** `xwayland-satellite :0` running for **both** Flatpak Qt5 apps (xcb plugin) **and** xcb-only AppImages (e.g., FireAlpaca 2.16.0). Manual test successful 2026-06-23 (FireAlpaca launches cleanly with `DISPLAY=:0 QT_QPA_PLATFORM=xcb`). Requires permanent startup: `spawn-at-startup "xwayland-satellite" ":0"` in `dots/niri/config.kdl` (pending implementation).

* **Portal AccessDenied (2026-06-10, fixed 2026-06-17):** `services.dbus.implementation = lib.mkForce "dbus"` (xdg-portal 1.20.4 pidfd bug, flatpak#1953). File pickers work.

* **XDG FileChooser Portal Routing (2026-06-19):** Gnome backend advertises `FileChooser` but doesn't implement it. Fix: `xdg.configFile` routes `org.freedesktop.impl.portal.FileChooser=gtk` (durable). Runtime file removed before switch.

* **Ollama VRAM/RTD3 (2026-06-17):** `OLLAMA_KEEP_ALIVE=5m`, `OLLAMA_KV_CACHE_TYPE=q8_0`, `OLLAMA_MAX_LOADED_MODELS=1`.

* **Playwright MCP (2026-06-15):** `scripts/playwright-mcp-nix` pins nix chromium. Pending gateway restart (kill+revive).

* **TMPDIR split (2026-06-17):** User → `~/Storage/tmp`; daemon → `/nix/tmp`; Makefile `REBUILD_TMPDIR := $(HOME)/Storage/tmp`.

* **Build fallback (2026-06-24):** Makefile `switch` carries `--option fallback true` to work around expired TLS cert on lantian cachy-kernel substituter. Substituter `https://attic.xuyh0120.win/lantian` serves `nix-cache-info` directly (valid cert), but 307-redirects NAR fetches to `us-central-1.telnyxstorage.com` with expired cert. Default behavior (fallback=false) halts build; fallback enables source compilation for affected packages instead. **Revert condition:** Once cert is renewed upstream, remove Makefile flag or migrate to permanent `nix.settings.fallback = true` in `nixos/configuration.nix` (superior home for resilience default). **Verification (2026-06-24):** Local clock, CA bundles (nss-cacert-3.123), and source hosts verified clean — pure upstream server-side issue. Optional: report cert expiry to github.com/xddxdd/nix-cachyos-kernel.

---

## 5. Niri Compositor + Noctalia v5 — PRIMARY DESKTOP (2026-06-17, Sole WM as of 2026-06-28)

**Status (2026-06-28):** niri + Noctalia v5 are the **only** desktop. Hyprland + ii/quickshell removed (see commit ee2efb4). niri is the default session launched by greetd/tuigreet.

**Phase 1 (2026-06-17):** Fully installed. Noctalia bar, wallpaper picker, 191 keybinds, touchpad toggle (F10), `center-focused-column "on-overflow"`, `#B4FF00` focus-ring, starship `force=true`, compositor-aware Krita. Rebuild verified; clean re-login confirmed.

**Upstream Work (2026-06-24, Verified 2026-06-25):** Upstream `noctalia-dev/noctalia` shipped major plugin work (commit `918add87c` + follow-ups): **`[[panel]]` entry kind restored**; **`ui.input`, `ui.scroll`, `ui.select`, `ui.slider`, `ui.toggle` exposed** to plugins; panels inherit `keyboardMode = OnDemand` (typeable text-input out-of-box). Flake.lock updated to `623210223c` (2026-06-25 UTC, 5.0.0 release). Fork branch `lowcache/noctalia:plugin-ui-input` (our exposure work) is **superseded** — archived, no PR needed. Issue #3137 closed.

**Plugin Architecture — Verified & Locked (2026-06-25):** IPC verified against noctalia source: `noctalia msg plugin lowcache/claude:pulse all <event>` dispatches to `onIpc(event, payload)` in bar widget. No data-return limitation from plugins. Three-nerve foundation (perceive + act + pulse) has **zero C++ fork requirement**:
- **Perceive:** MCP shim queries system directly (`niri msg`, `playerctl`, `/sys`); noctalia IPC used only for noctalia-internal state (secondary).
- **Act:** `noctalia msg <target> <action>` request/response works as-is (action path proven).
- **Pulse:** claude Stop-hook → `noctalia msg plugin lowcache/claude:pulse all <event>` → plugin animates via `onFrameTick`. Frame-tick animation confirmed working.

**Plugin Scaffold (2026-06-25, Rewritten):** Ground-truth API verified against noctalia source (rev 623210223c). Key fixes:
- Bar widget table: `barWidget.*` (not `widget.*`)
- IPC dispatch: `noctalia msg plugin lowcache/claude:pulse all <event> [payload]`
- onIpc signature: two args `(event, payload)` (not one)
- Theme commands: `color-scheme-set <source> <name>` (not `theme-set`)
- Glyphs: Tabler icon names (robot, brain, message-dots, tool, bell-ringing, circle-check, alert-triangle verified)
- `runInTerminal(cmd)` takes one string; all run via `/bin/sh -c <string>`
- `noctalia.notify` works (luau-only, no generic notify IPC)

**Philosophy (2026-06-24, Locked):** Shell as Claude's **desktop senses + actuators**, not chat UI reimplementation. Design NEW v5 plugins inspired by v4 (not ports) that add native value. Comprehensive design doc at decisions.md #24-26.

### Workspace Navigation (2026-06-20)
Added move-column-to-workspace keybinds: `Mod+Shift+Page_Up/Down` and `Ctrl+Mod+Shift+Left/Right` move focused column to adjacent workspaces. Tested; helpful for organizing VM windows.

### Quake Terminal — FIXED, Cold-Start Socket Bug (2026-06-25)

**Architecture:** niri only **spawns** shell script. kitty owns all window logic via wlr-layer-shell singleton + remote control.
- `kitten quick-access-terminal` → singleton; `--single-instance --instance-group quick-access --toggle-visibility`.
- Listen socket: `unix:/run/user/1001/kitty-quake` (kitty appends PID).
- Toggle (preserves geometry): `kitten @ --to unix:<sock> resize-os-window --action=toggle-visibility`.
- Live geometry: `kitten @ --to unix:<sock> resize-os-window --action=os-panel --incremental edge=<edge> lines=<N>`.

**Files in place (2026-06-18):** `dots/kitty/quick-access-terminal.conf`, `dots/niri/scripts/quake.sh`.

**Keybind wiring (CONFIRMED LIVE):** `Mod+Return` = toggle | `Mod+Shift+Return` = position | `Mod+Alt+Return` = height | `Mod+Ctrl+Return` = aspect. Wired in `dots/niri/config.kdl:136-139`.

**Focus policy (2026-06-20):** Set to `on-demand` in `quick-access-terminal.conf` to allow niri keybinds to fire while panel open. Previously `exclusive` monopolized keyboard and blocked compositor keybinds.

**Cold-start bug FIXED (2026-06-25):** `sock()` helper returned non-zero when no socket existed (terminal not yet running), triggering `set -e` abort under `set -euo pipefail` before the script could `launch`. The panel could only work if already running. On this tmpfs-root system, `/run` is wiped each boot → socket always gone at startup → first keypress always failed. Root cause: query that can legitimately return empty (glob, ls, grep) made fatal. Fix: `sock()` ends in `|| true`. Verified: cold launch, toggle, geometry changes all work with state persisting. No rebuild needed (script is live symlink).

**Critical gotchas:** (1) Kitty conf does NOT support trailing `#` comments — own-line only. (2) Orphaned `.kitty-wrapped` processes hold abstract socket → kill by pid.

### Noctalia v5 Bar — Dual Wrap-Around Layout (Top+Left L-Frame, 2026-06-22 — COMPLETE, LIVE)

**Status (2026-06-22, live):** Dual wrap-around bar design **fully styled and live in runtime state** `~/.local/state/noctalia/settings.toml`, **now on Ayu Green custom palette**. Validated, hot-reloaded, user-approved ("awesome"). Replaces prior bottom-island 3-capsule layout. **NOT yet committed to git** (user-deferred; lower priority).

**Design:** A **top horizontal bar** (full width, owns top edge + outer corners) + a **left vertical bar** (full height, owns left edge + outer corners) that **join at a right angle in the top-left corner**, reading as one continuous L-frame.

**Layout (locked):**
- `[bar.top]`: position=top, full width. Widgets: empty start · **clock centered** · `tray · network · volume · battery · control-center` at end. Outer corners rounded (16); seam corner squared (radius_bottom_left=0) to fuse with left bar.
- `[bar.side]`: position=left, full height. Widgets: `launcher · workspaces` at start · `cpu · gpu_usage · ram · gpu_temp · cputemp` at end. Outer corners rounded (16); seam corner squared (radius_bottom_right=0) to meet top bar flush.
- Both bars: `reserve_space = true`, forcing exclusive layout zones (left bar's zone pushes top bar's left edge to its right; bars join without gap). Both `layer="top"`.

**Styling (2026-06-22, COMPLETE):**
- **Colors:** Muted green text + gold icons via **Ayu Green palette** (primary `#AAD94C` lime, secondary `#E6B450` gold via theme roles `color="primary"` + `icon_color="secondary"`). Unified across bar/kitty/starship. Theme-coherent, not garish.
- **Presence strategy:** Shadow + no border. Border at seam breaks continuity; shadow alone defines the bar on dark wallpaper (acceptable tradeoff for seamless L-join).
- **Widget configuration solution (VERIFIED):** Widget config is global per **type** (`[widget.temp]` affects all `temp` instances), BUT Noctalia supports **per-instance overrides** via named instances + `type=` key. Applied: left bar now has both `temp` (GPU) and `cputemp` (CPU temperature) via `[widget.cputemp] type="sysmon" stat="cpu_temp"`. Valid `sysmon` stats (probed): `cpu_usage`, `cpu_temp`, `gpu_usage`, `gpu_temp` only (NOT ram/disk/network).
- **Technical constraints discovered (for future ref):** (1) No per-bar background-color key; bar surface bound to theme's `surface` role. (2) Can't recolor theme roles from settings.toml on builtin themes — requires custom palette. (3) `reserve_space` is the operative key for multi-bar layout. (4) Daemon reserializes settings.toml on GUI edits; hand-edits + `noctalia msg config-reload` work, but GUI can clobber.
- **Theme Sync Note:** Noctalia includes `kitty` and `starship` in its template management, so it auto-generates theme-specific config blocks (`~/.config/kitty/current-theme.conf`, starship colors) when switching themes. The color-engine also writes to these targets; Noctalia's template blocks take precedence (included after). This auto-sync keeps bar/kitty/starship aligned without manual edit.

**Backups:** `~/.local/state/noctalia/settings.toml.bak.20260622-112626` (final dual wrap-around + muted accents). Reversible via `cp` + `noctalia msg config-reload`.

**Design rationale:** Matches the exo (Material 3 shell) wrap-around bar aesthetic — a continuous visual frame (L-shaped bar wrapping the screen corner). Noctalia natively supports multiple bars on different edges + per-corner radius, so the look is achievable without a separate widget framework.

**Next:** Capture runtime state to `dots/noctalia/config.toml`, commit to git (user-deferred).

### Claude Code Companion Plugin (2026-06-25 — V1 Live, 2026-06-26 Icon & Roadmap Update)

**Status (2026-06-26):** V1 live and verified. Pulse widget animating in top bar. MCP shim and launcher hardened against crash vectors via independent review (tether/Gemini). **Perceive + Act + Pulse all verified end-to-end; MCP robustness validated.**

**Live state:**
- **Plugin path:** Symlink `~/.local/share/noctalia/plugins/claude` → `~/CodeRepo/noctalia-claude-plugin/` (GitHub: `github.com/lowcache/noctalia-claude-plugin`).
- **Repository:** Plugin is now its own git repo with independent history and MCP shim. Pushed to GitHub 2026-06-26.
- **Pulse widget:** `bell-ringing` glyph in **top bar `center`**. States: `idle` (robot), `turn_start` (brain), `tool_start` (wrench), `needs_attention` (bell-ringing, red), `turn_end` (bell-ringing, primary). All animated via `onFrameTick`. **Icon update (2026-06-26):** `turn_end` changed from checkmark to bell (persists until next prompt, signals "awaiting your next message").
- **Session hooks (wired 2026-06-25):** Merged into `~/.claude/settings.json`; pulse driven by SessionStart→idle, UserPromptSubmit→turn_start, PreToolUse(*)→tool_start, PostToolUse→turn_start, Notification→needs_attention, Stop→turn_end. All commands resilient to noctalia being offline.
- **MCP shim:** Registered at project scope in `~/.nix-config/.mcp.json` (stdio, python3 shim/noctalia-mcp.py). **Handshake verified and approved 2026-06-25**. Tools: `get_window`, `get_workspace`, `get_media`, `get_shell_state`, `notify`, `set_theme_mode`, `set_color_scheme`, **`remember`** (2026-06-26, writes to global inbox). **Live test (2026-06-25 + 2026-06-26):** `get_window` returned focused kitty task, `get_workspace` returned eDP-1 1920×1200, `get_shell_state` returned JSON, `notify` fired desktop toast, `remember` wrote durable notes to `~/.memory/inbox/`.
- **Launcher `/cc`:** One-shot `claude` invocations via `runInTerminal` (real TUI with full fidelity, not chat emulation).
- **Reversibility:** Settings backup at `~/.local/state/noctalia/settings.toml.bak.20260625-092856.preplugin`.

**Verified perceive/act/pulse chain (2026-06-25):**
- **Perceive:** `get_window` + `get_workspace` + `get_shell_state` returned live environment data mid-session.
- **Act:** `notify` fired a desktop toast successfully ("MCP shim live — perceive + act confirmed").
- **Pulse:** SessionStart + UserPromptSubmit hooks both returned `ok: dispatched 2`, confirming session-state tracking active.

**Plugin Memory (2026-06-26):** `~/CodeRepo/noctalia-claude-plugin/.memory/` scaffolded and registered via `memd init`. Contains clean state/decisions/mistakes/todo/inbox. Memd auto-discovers new projects; index lists it with live status.

**2026-06-26 Review & Hardening:** Independent (tether/Gemini, flash-high, 52s) review of MCP shim and launcher code found 6 issues; fixes applied and verified.

### Claude Code Plugins — Token Optimization (2026-06-25)

**Cleanup (2026-06-25):** Disabled 14 of 18 installed plugins to reduce per-turn token overhead (unused skills were injected into system prompt every message, competing for context). Disabled groups: crypto/Web3 (6), redundant Nix (5), frontend design (2), rust-skills (1). Remaining enabled (4): `nix-dev`, `devenv`, `feature-dev`, `impeccable`.

**Impact:** Savings visible on next session (hooks/settings take effect at session start). Fully reversible: `claude plugin enable <name>@<marketplace>` restores any disabled plugin. Also removed `rtk hook claude` from `PreToolUse` hooks in settings.json (simplification).

### Noctalia Scratchpad Plugin (2026-06-24 — Active)

- **Status:** Desktop widget + launcher provider for note-taking. Live-installed at `~/.local/share/noctalia/plugins/scratchpad/`.
- **Capabilities:** Add notes, delete, clear all, desktop widget with input field.
- **Architecture:** Shares state via `noctalia.state` + `notes.json`; launcher provider and desktop widget synchronized.
- **UI controls:** `ui.input`, `ui.scroll` — both newly exposed to plugins (Layer 1 complete 2026-06-24).

---

## 6. Nix-on-Droid — Aarch64 Android Target (2026-08-02 — COMPLETE)

**Architecture:** `nixOnDroidConfigurations.default` in the existing volnixos flake. One `flake.lock`, evaluated on volnix but built on the phone. Portable Home Manager layer (`home/common/`) shared with desktop.

**Portable layer (`home/common/`):** Platform-agnostic configuration — fish shell (aliases, abbrs, functions, PATH), git config, micro (syntax/tools), direnv, common CLI packages (ripgrep, fd, fzf, eza, jq, yq, coreutils, etc.). Extracted from prior volnix `home/shell.nix` and `home/pkgs.nix`; both hosts import it via `imports = [ ../home/common ]`. Works because `programs.fish.{shellInit,interactiveShellInit}` are `types.lines` (mergeable) and aliases/functions/packages are merging options (no host redefines a shared value). **Verified behavior-preserving refactor (2026-08-02):** Desktop package list (224 entries), aliases, functions, git settings, micro settings, interactive shell init byte-identical before/after.

**Host-specific layers:**
- **volnix** keeps `home/shell.nix` (niri/Noctalia integration, systemd units, sops-nix secrets), `home/pkgs.nix` (build toolchains node/go/pandoc, dev runners, ripgrep-all).
- **droid** has `droid/home.nix` (nix-on-droid module configuration), `droid/agents.nix` (agent tooling — claude-code, claude-code-router, codex, rtk, mcp-server-sequential-thinking, llmfit + llm-agents packages: ccstatusline, claude-plugins, opencode, zaly, cc-switch-cli, parallel-cli, toon, happy-coder, antigravity-cli [supersedes gemini-cli; llm-agents 1.1.8 fully substitutable on aarch64]).

**Phone-agent MCP unchanged:** nix-on-droid is not Termux. It is a separate Android package (`com.termux.nix`) with its own sandbox — not an authorized caller of Termux:API. Phone-agent MCP server stays in Termux and is accessed over the network (Tailscale loopback or local network) exactly as now. nix-on-droid provides the declarative dev environment **alongside** Termux, not replacing it. The `android-integration.*` options enabled in the system layer are nix-on-droid's own intent-broadcast mechanism; they don't change this architecture.

**Closure budget achieved (2026-08-02, with llm-agents + numtide cache):**
- **Naive port (pre-refactor):** 83 derivations built (incl. `nodejs` from source), 158 MiB download, 3906 MiB unpacked.
- **With common layer only:** 87 derivations built (all HM glue; no app source compiles), 399 MiB download, 2864 MiB unpacked.
- **With common layer + agent stack:** 95 derivations built (all HM glue + agent tooling), **362.52 MiB download, 4788.43 MiB unpacked, zero source builds**.
- **Upstream requirements:** 
  - nix-on-droid's proot-termux: `https://nix-on-droid.cachix.org` (key `nix-on-droid.cachix.org-1:56snoM…`). Device enables by default; volnix must pass key when evaluating.
  - llm-agents packages: `https://cache.numtide.com` (key `niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=`). Wired in `droid/default.nix` to avoid phone source builds.

**Constraints discovered:**
- **nix-on-droid is not Termux.** It is a separate Android package (`com.termux.nix`) running in its own sandbox — not an authorized caller of Termux:API. Phone-agent MCP stays in Termux, accessed via network (Tailscale or loopback), just as now.
- **No aarch64 emulation on volnix:** `boot.binfmt` is AppImage-only. Flake evaluation happens on volnix (`nix flake check`, `make droid-check` work); system layer evaluation fails (upstream's `modules/user.nix` runs IFD with aarch64 derivation). Build happens on the phone (`nix-on-droid switch --flake .`).
- **`--impure` is mandatory for evaluation:** nix-on-droid references proot-termux via `builtins.storePath`, requiring impure eval. Upstream's own CLI (`nix-on-droid.sh:32`) passes `--impure`.
- **proot-termux only on `https://nix-on-droid.cachix.org`** (key `nix-on-droid.cachix.org-1:56snoM…`). Device enables it; volnix must pass key when evaluating. Already wired in `flake.nix` comments.
- **nix-on-droid tracks **master** (no stable release). Newest tag is `release-24.05` (~2 years old). Using master is intentional for latest fixes.

**Makefile targets added (2026-08-02):**
- `make droid-check`: Evaluate the HM layer (aarch64-linux), report any eval errors.
- `make droid-plan`: Dry-run the HM activation package, show closure size and what would be fetched.
- `make droid-switch`: (Placeholder for future; actual switch runs on the phone via `nix-on-droid switch --flake .`).

**Verification (2026-08-02):**
- Full system dry-build (volnix): Desktop home.packages byte-identical to pre-refactor baseline, zero changes.
- Lints (deadnix, statix, nix flake check): clean.
- Phone dry-build: 362.52 MiB download / 4788.43 MiB unpacked, zero source builds.
- `make droid-check` evaluates successfully.

### Nix-on-Droid Activation Diagnostic Sequence (2026-08-02, In Progress)

**PTY Failure Isolation (2026-08-02):** First `nix-on-droid switch` failed during `installPackages` phase with `error: getting pseudoterminal attributes: Permission denied`. Multiple hypotheses tested and eliminated via on-device diagnostics:
- NOT general pty unavailability: trivial derivations build cleanly (`tree-2.3.2-man` user-environment succeeds)
- NOT nix version (2.18.8 current, 2.34.8 incoming post-activation)
- NOT TMPDIR/disk space/stdout piping issues
- **Likely trigger:** Full ~500-package nix-on-droid-path closure; single-package installs work

**Bisect test (agents.nix dropped, 2026-08-02):** Dropped `droid/agents.nix` and re-ran `nix-on-droid build`. Build succeeded cleanly, generation `9y0bmwnw5z6wnsgqf1wn0qlddf273mc1-nix-on-droid-generation` created. Full nix-on-droid-path identified: `/nix/store/sks5micnwsl228ifblhy422ybwnqwf0w-nix-on-droid-path`. Confirms flake/build-graph are correct; error confined to activation step.

**Current test:** Direct `nix-env --profile /tmp/testprof2 --install <full-nix-on-droid-path>` to reproduce the pty failure in isolation and determine if it's environment-specific or a nix upstream issue. In progress.

**Version bump pending:** Successful activation will upgrade nix from 2.18.8 to 2.34.8 as part of new generation.

**Profile pollution (2026-08-02):** Early diagnostic `nix profile install` calls against live profile converted it from nix-env style to `nix profile` style (created `manifest.json`). This flipped the activation code path and manufactured a secondary error unrelated to the pty issue. Cleanup pending: `nix profile remove 1 2`.

---

## 7. Application Status (2026-07-14, Updated 2026-07-31)

### Krita 6.0.1 native + Font Gallery pykrita Plugin (2026-06-22 — User-Text Input, Implementation Validated)

- **Status:** Font Gallery pykrita plugin at `~/Storage/krita-master/krita/pykrita/font_gallery/` uses **Qt rasterization** (SVG text-shape insertion crashed Krita 6.0.1 err=84; Qt path bypasses this entirely). **Enhanced (2026-06-22):** Plugin now supports **user-typed text input** (QLineEdit + size spinbox, 8–600 pt, default 96). Implementation syntax-validated; multi-line rendering validated standalone (819×346 ARGB32, 37328 opaque pixels); layer insertion proven working via prior sample-text test on canvas.
- **Files:** `font_gallery.desktop` + `font_gallery/{__init__.py,font_gallery.py}`. Targets PyQt6 (Krita 6 is Qt6); uses scoped `DockWidgetFactoryBase.DockPosition.DockRight` enum.
- **Krita Installation (2026-06-22):** **Nix** `/nix/store/...-krita-unwrapped-6.0.1` — loads cleanly, Font Gallery plugin active. **Flatpak** — uninstalled (was crashing SIGABRT on launch; removed to avoid PATH conflicts). Plugin only available in Nix build.
- **Limitation (honest):** Output is a **raster image**, not editable vector text. To change wording, retype and double-click again for a fresh layer.

### GIMP (fallback)

- **Status:** `org.gimp.GIMP` 3.2.4 (Flatpak, stable) installed as fallback for text-on-raster work.

### Color Scheme — Ayu Green Unified (2026-06-22)

- **Status:** Live and synced across Noctalia bar, kitty terminal, starship prompt.
- **Theme file:** `dots/color-engine/themes/ayu_green.json` — validated (35 tokens, 77 roles). Palette: lime `#AAD94C`, gold `#E6B450`, cyan `#39BAE6`, navy base `#1F2430`.

### Cargo-Installed Tools (2026-07-31)

- **lonkero 3.5.0 (2026-07-31):** CLI tool. Installed via `RUSTFLAGS="-C link-arg=-Wl,-rpath,/run/current-system/sw/share/nix-ld/lib" nix-shell -p pkg-config openssl --run 'cargo install lonkero'`. Uses persistent RPATH to `/run/current-system/sw/share/nix-ld/lib` for openssl linkage (supported by `programs.nix-ld.libraries` containing `openssl.out` at `nixos/configuration.nix:288`). Required clearing stale fish universal variable `OPENSSL_DIR` that had been set to `openssl-3.6.3-dev` (see mistakes.md #12). Runtime linking verified: `libssl.so.3 => /run/current-system/sw/share/nix-ld/lib/libssl.so.3`, `libcrypto.so.3 => /run/current-system/sw/share/nix-ld/lib/libcrypto.so.3`. Binary executes cleanly (`lonkero --version` confirms).
