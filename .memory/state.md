---
type: state
project: Vol NixOS
last_updated: 2026-08-24
status: active
---

# System State Inventory (`memory/state.md`)

This file is the single source of truth for the active configuration, mapping, and hardware state of **Vol NixOS**.

---

## 1. System & Hardware Profile

* **Hostname:** `volnix` | **OS:** NixOS 26.11 (Zokor) | **Shell:** Fish (HM)
* **Current generation:** system-238 (`/nix/store/fk85s3nrsmil8f8m136lvw0495sby5yg-nixos-system-volnix-26.11.20260805.b7c2ada`)
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

**Imperative nix-env profiles (2026-07-27):** `~/.local/state/nix/profiles` persisted to `persist.nix` (canonical store where `nix-env -iA nixos.<pkg>` writes `profile-N-link` + `channels` generation + manifest). Compat symlink `~/.nix-profile → ~/.local/state/nix/profiles/profile` recreated declaratively via `home.file` with `force = true` at each activation. Caveat: `nix-env -iA nixos.*` requires the `nixos` channel; confirm `nix-channel --list` post-boot if installs can't resolve it. Rationale: decisions.md #30.

**Cache enforcement (active 2026-06-17):** `xdg.cacheHome = "$HOME/Storage/.cache"`; `TMPDIR`, `PIP_CACHE_DIR`, `CLAUDE_CODE_TMPDIR` → `~/Storage/tmp`. `.cache/llmfit`, `.cache/noctalia` persisted.

**Quarantined fonts (2026-06-21):** Corrupt font `NoracleNerdFont-Regular.otf` moved to `~/Storage/tmp/quarantined-fonts/`. `fc-cache -f` rebuilt.

**Flatpak data (persisted 2026-06-22):** `/var/lib/flatpak` and `~/.local/share/flatpak` persisted (`hardware-configuration.nix:91`, `persist.nix:110`). Flathub remote added; `org.gimp.GIMP` 3.2.4 installed. Host fonts (`~/.local/share/fonts`, 2772 files) mounted read-only into Flatpak sandboxes via `filesystems=host`.

**Phone-agent ingest (2026-08-06):** Staged files from phone arrive at `~/ingest/staged/` (managed by phone-ingest-sync.timer). Delivered files moved to `~/ingest/delivered/` after hash verification.

**Android tools (2026-08-21):** `~/Android` (Studio SDK, ~1.4 GB) and `~/.android` symlink to `~/Storage/`. `/var/lib/waydroid` bind-mounted from `/persist/var/lib/waydroid` (~2.4 GB). Both moved to avoid filling the 4 GB impermanence tmpfs root (mistakes.md #13).

**Waydroid userdata (2026-08-21):** `~/.local/share/waydroid` bind-mounted from `/persist/.local/share/waydroid` to persist app installs/data across reboots.

---

## 3. MicroVM Guest Network (2026-08-06 — Confirmed Working)

* **net-gate (Tor relay):** Host `vm-netgate` → `192.168.100.1`; guest → `192.168.100.2`. Tor `9040`/DNS `5353`/SOCKS `9050`.
* **tailscale (Tailnet access):** Host `vm-tailscale` → `192.168.101.1`; guest → `192.168.101.2`. Service `microvm@tailscale` active (autostart enabled). Guest runs `tailscaled` with auth-key from `/persist/var/lib/tailscale-vm/authkey`, tailnet IP `100.66.249.117`. Host reaches tailnet via static route `100.64.0.0/10 via 192.168.101.2 dev vm-tailscale` (host itself is not a tailnet node). **Start/restart:** `sudo systemctl start microvm@tailscale`. Do not use `make run-tailscale` while unit is active (fights over tap/socket).
* **VM tap interfaces** `unmanaged` in NetworkManager.

---

## 4. Active Workarounds

* **`make switch-detached` PATH Fix (2026-07-28 — FIXED):** Transient systemd units inherit minimal PATH (no `git`), breaking lix's flake fetcher. Fix: Makefile target passes `--setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin` to `systemd-run`. Verified 2026-07-28.

* **Krita G'MIC Plugin Crash — FIXED & VERIFIED (2026-07-14):** Patched via `overrides/gmic-qt-filtersview-nullptr-contextmenu.patch`; applied through `krita-plugin-gmic-patched` in `home/pkgs.nix`, bundled into `krita-wrapped`. Full root-cause narrative: decisions.md #21.

* **Ollama Pinned to 0.31.1 (2026-07-28):** `nixos/overlays/ollama.nix` pins `ollama-cuda` to pre-update nixpkgs rev `d407951`. Upstream 0.32.3 fails to build (CUDA Toolkit not found via setup-cuda-hook). Revert condition: retry 0.32.x+ on next flake update.

* **Flake-Update Overlays Active (2026-07-28):** `nixos/overlays/pandas-stubs.nix` (pytest 9.1.1 promotes a warning to a hard error under `filterwarnings=error`; overlay sets `PYTEST_ADDOPTS="-W ignore::pytest.PytestRemovedIn10Warning"`) and `nixos/overlays/niri.nix` (pins `libdisplay-info` to 0.3.0; niri 26.04's vendored `libdisplay-info-sys` caps at `<0.4.0`, nixpkgs bumped past it). Both cache-hit, no rebuild cost. Revert conditions documented in each overlay header; full incident detail archived (see archive_entries).

* **XWayland Satellite (2026-06-23):** `xwayland-satellite :0` running for Flatpak Qt5 apps and xcb-only AppImages (e.g. FireAlpaca). Manual-start only — permanent `spawn-at-startup` wiring still open (todo.md).

* **Portal AccessDenied — FIXED (2026-06-17):** `services.dbus.implementation = lib.mkForce "dbus";` (xdg-portal 1.20.4 pidfd bug). Full root cause: mistakes.md #10.

* **XDG FileChooser Portal Routing (2026-06-19):** Gnome backend advertises `FileChooser` but doesn't implement it; `xdg.configFile` routes `org.freedesktop.impl.portal.FileChooser=gtk` (durable, declarative).

* **Ollama VRAM/RTD3 (2026-06-17):** `OLLAMA_KEEP_ALIVE=5m`, `OLLAMA_KV_CACHE_TYPE=q8_0`, `OLLAMA_MAX_LOADED_MODELS=1`.

* **Playwright MCP (2026-06-15):** `scripts/playwright-mcp-nix` pins nix chromium.

* **TMPDIR split (2026-06-17):** User → `~/Storage/tmp`; daemon → `/nix/tmp`; Makefile `REBUILD_TMPDIR := $(HOME)/Storage/tmp`. Rationale: decisions.md #13.

* **Build fallback (2026-06-24):** Makefile `switch` carries `--option fallback true` — substituter `attic.xuyh0120.win/lantian` 307-redirects NAR fetches to a host with an expired TLS cert; fallback compiles from source instead of halting the build. Revert condition: once upstream cert is renewed, remove the flag (or migrate to permanent `nix.settings.fallback = true`).

---

## 5. Phone-Agent File Transfer (2026-08-06 — Confirmed Working, Pull-Only by Design)

**Mechanics:** Phone stages a file (Termux hooks or manual placement) → `phone-ingest-sync.timer` (every 2 min) → `phone-agent phone.ingest.fetch` pulls it → lands in `~/ingest/staged/`, sha256-verified, moved to `~/ingest/delivered/`.

**Manual triggers:** `systemctl --user start phone-ingest-sync.service` (immediate pull); `phone-agent phone.ingest.list '{"limit":50}'` / `phone-agent phone.ingest.fetch '{"name":"file.pdf","delete_after":true}'` (hand-invoke; caller must decode base64 + verify sha256 itself).

**Limitation:** All 34 phone-agent tools are phone→laptop only. Laptop→phone needs `phone.system.termux_exec`/`rish` to have the phone `curl` from the host — requires a DNAT entry (`nixos/vms.nix:225`) plus a host HTTP server. Not implemented. Tailscale Taildrop is likewise phone→laptop only; the web UI has no file-transfer surface.

---

## 6. Nix-on-Droid — Aarch64 Android Target (Generation 5 Live, Verified 2026-08-03)

**Architecture:** `nixOnDroidConfigurations.default` in the volnixos flake (one `flake.lock`); portable `home/common/` HM layer shared with desktop. `nixpkgs-droid`/`home-manager-droid` pinned to `nixos-25.11` (glibc 2.40) — desktop stays on unstable (glibc 2.42). Full root-cause narrative for the glibc 2.42 TCGETS2 regression and the proot `_defaultUnpack` chmod bug: decisions.md #31, #32.

**Live state (verified 2026-08-03):** rtk 0.44.0, mcp-gateway 3.3.2, opencode 1.1.14, claude 2.1.140, codex 0.92.0 — all glibc-2.40-224, zero glibc-2.42 in the runtime closure. `tty` returns `/dev/pts/0`; claude-code's full Ink/React TUI renders correctly on-device (the linchpin test). Phone is daily-usable.

**Nerd Font fix:** `droid/default.nix` sets `terminal.font` to JetBrainsMono Nerd Font, installed as `~/.termux/font.ttf` on activation.

**Host-specific layers:** volnix keeps `home/shell.nix` + `home/pkgs.nix` (nixos-unstable). droid has `droid/home.nix` + `droid/agents.nix` + `droid/backports.nix` (rtk, mcp-gateway, `prootUnpack` override; nixos-25.11).

**Makefile targets:** `make droid-check` / `droid-plan` / `droid-switch`.

**Still open:** android-integration wiring choice (disabledModules patched copy vs. minimal `xdg-open` shim); whether tether needs `antigravity-cli` or gemini-cli 0.25.2 suffices on droid. See todo.md.

---

## 7. Niri Compositor + Noctalia v5 — PRIMARY DESKTOP

**Status:** niri + Noctalia v5 are the sole desktop (Hyprland + ii/quickshell fully removed, commit ee2efb4). niri is the default greetd/tuigreet session. 191 keybinds, `center-focused-column "on-overflow"`, `#B4FF00` focus-ring, starship `force=true`, compositor-aware Krita.

**Noctalia v5 plugin API (locked, verified against source rev 623210223c):** `[[panel]]` entry kind + full `ui.*` control exposure (input/scroll/select/slider/toggle) shipped upstream 2026-06-25; our fork branch is superseded/archived (decisions.md #23). IPC: `noctalia msg plugin <id> all <event> [payload]`; bar widget table is `barWidget.*`; theme commands are `color-scheme-set <source> <name>`; `runInTerminal(cmd)` takes one string via `/bin/sh -c`.

**Workspace navigation (2026-06-20):** `Mod+Shift+Page_Up/Down` and `Ctrl+Mod+Shift+Left/Right` move focused column to adjacent workspaces.

**Quake terminal (2026-06-25, live):** `kitten quick-access-terminal` (wlr-layer-shell singleton) — niri only spawns the script, kitty owns window/geometry via remote control on `unix:/run/user/1001/kitty-quake`. Keybinds: `Mod+Return` toggle, `Mod+Shift+Return` position, `Mod+Alt+Return` height, `Mod+Ctrl+Return` aspect (`dots/niri/config.kdl:136-139`). Focus policy `on-demand` (not `exclusive`, which blocked compositor keybinds). Cold-start socket bug fixed (`sock()` helper now ends `|| true` under `set -euo pipefail`). Architecture rationale: decisions.md #16. Gotchas: kitty conf has no trailing `#` comments; orphaned `.kitty-wrapped` processes hold the abstract socket (kill by pid). Full narrative archived (see archive_entries).

**Bar — dual wrap-around L-frame (2026-06-22, live, NOT yet committed to git — user-deferred):** Top bar (full width) + left bar (full height) join at top-left corner via `reserve_space = true` on both, squared seam corners, rounded outer corners. Ayu Green palette (`#AAD94C` lime primary, `#E6B450` gold secondary) unified across bar/kitty/starship via `dots/color-engine/apply_theme.py`. Backup: `~/.local/state/noctalia/settings.toml.bak.20260622-112626`. Next: capture to `dots/noctalia/config.toml` and commit (deferred, see todo.md). Full technical-constraints narrative archived (see archive_entries).

**Claude Code Companion Plugin (2026-06-26, V1 live):** `~/.local/share/noctalia/plugins/claude` → `~/CodeRepo/claude-companion/noctalia-claude-plugin/` (own repo, `github.com/lowcache/noctalia-claude-plugin`). Pulse widget (`bell-ringing` glyph, top bar center) driven by Claude session hooks (SessionStart/UserPromptSubmit/PreToolUse/PostToolUse/Notification/Stop, merged into `~/.claude/settings.json`). MCP shim registered at `~/.nix-config/.mcp.json` (stdio): `get_window`, `get_workspace`, `get_media`, `get_shell_state`, `notify`, `set_theme_mode`, `set_color_scheme`, `remember`. Launcher `/cc` runs one-shot `claude` invocations via `runInTerminal`. Design philosophy (shell as senses/actuators, not a chat-UI port): decisions.md #24. Full verification narrative archived (see archive_entries).

**Plugin token optimization (2026-06-25):** 14 of 18 installed Claude Code plugins disabled to cut per-turn system-prompt overhead; 4 enabled (`nix-dev`, `devenv`, `feature-dev`, `impeccable`). Reversible via `claude plugin enable <name>@<marketplace>`.

**Scratchpad plugin (2026-06-24, active):** Note-taking widget + launcher provider at `~/.local/share/noctalia/plugins/scratchpad/`, shares state via `noctalia.state` + `notes.json`.

---

## 8. Documentation Platform — Hugo + E25DX (2026-08-15, Live; SEO fix 2026-08-23)

* **Status:** Wiki migrated from MkDocs to Hugo (0.164.0) + E25DX theme (Hugo Module).
* **Repository:** Independent repo at `~/CodeRepo/blogs/wiki` (main pushed), published as `lowcache/volnixos-wiki`. No longer symlinked into `.nix-config`.
* **Build:** `build.sh` (shared by `make build` and Workers Builds); pagefind post-build (`npx -y pagefind@1` fallback for Workers image).
* **Deployment:** Workers Builds integration pending (dashboard: set Build command `./build.sh`, build var `HUGO_VERSION=0.164.0`). Current deploys via `make deploy` (direct wrangler).
* **Theme gotchas (load-bearing — do not omit):**
  1. `[[module.imports]]` requires `ignoreConfig = true` (theme's `hugo.yaml` defines `theme: E25DX`; Hugo merges and fails without the ignore flag).
  2. Section pages need `layout: single` in front matter (no section template; omitting renders nothing).
  3. Sidebar navigation driven by presence flag `data/en/<section>/sidebar.yaml` (contents ignored; removal omits sidebar).
  4. Mermaid requires custom renderer at `layouts/_markup/render-codeblock-mermaid.html` (theme ships no third-party JS).
  5. Goldmark does not render markdown inside `<div markdown>` — rewrite as HTML.
  6. **`layouts/robots.txt` blocks non-Google crawlers by default (found 2026-08-23).** Theme template emits `Allow: /` for Googlebot/YandexBot/baiduspider/Applebot only, then a `User-agent: *` group with a per-page `Disallow:` for every page plus a trailing `Disallow: /`. bingbot and DuckDuckBot fell into the `*` group and were fully blocked. Fixed via a local `layouts/robots.txt` override (flat `Allow: /` for `*`, explicit `Sitemap:` line); committed, deployed, verified live (`Disallow` count for the `*` group: 31 → 0). Source: `$GOMODCACHE/github.com/dumindu/E25DX@.../layouts/robots.txt`. Mistake logged: see mistakes.md.
* **GSC deindexing incident (2026-08-16/17 → monitoring through ~2026-08-30):** `infernalcode.com` (Domain property, covers `wiki.infernalcode.com`) showed a spike from ~5 to 40 pages in "Crawled – currently not indexed" beginning ~2026-08-17, within 48h of the MkDocs→Hugo port. Google's own URL Inspection reported crawl allowed, fetch successful, indexing allowed, canonical clean — no technical fault found; content grew ~39% in the port and exactly one URL moved. [UNVERIFIED] causal mechanism — correlation with the port is the only evidence. Wiki sitemap had **never been submitted** in GSC — submitted 2026-08-23, 30/30 discovered same day. Blog sitemap (stale since 2026-08-02 at 39 URLs) refreshed to 50. GSC account note: the property lives under `lowcache.dev@gmail.com` (GSC user `/u/5/`), not the Chrome default-active `drawpdeadredd@gmail.com` — check the active account first if GSC appears empty.
* **Outstanding:** Workers Builds CI wiring, home page data-driven conversion, visual overhaul (palette port + centring), GSC Page Indexing recovery check (~2026-08-30, see todo.md).

---

## 9. Application Status

**Krita 6.0.1 + Font Gallery pykrita plugin:** Only the Nix build is in use (`pkgs.krita`, patched G'MIC bundled — see §4). Flatpak uninstalled 2026-06-22 (SIGABRT on launch). Font Gallery (`~/Storage/krita-master/krita/pykrita/font_gallery/`) rasterizes text via Qt `QPainter.drawText` (bypasses Krita's broken SVG text engine, err=84). Supports user-typed multi-line text + size spinbox (8–600pt). Output is a **raster image**, not editable vector text — retype and double-click for a fresh layer. Full root-cause/decision narrative: decisions.md #21. Outstanding: end-to-end UI test (todo.md).

**GIMP:** `org.gimp.GIMP` 3.2.4 (Flatpak) installed as raster-text fallback.

**Color Scheme — Ayu Green:** Live and synced across Noctalia bar, kitty, starship. Theme file `dots/color-engine/themes/ayu_green.json` (35 tokens, 77 roles). Palette: lime `#AAD94C`, gold `#E6B450`, cyan `#39BAE6`, navy base `#1F2430`.

**Cargo-installed tools:** `lonkero` 3.5.0 (2026-07-31) via `cargo install`, linked against `/run/current-system/sw/share/nix-ld/lib` (openssl) per `programs.nix-ld.libraries`; required clearing a stale fish universal var `OPENSSL_DIR` (mistakes.md #12).

**J-Space skill (2026-08-19, trial active):** Claude Code skill for workspace reasoning; locally patched for CLAUDE.md precedence + configurable `LEDGER_DIR`. Backups: `SKILL.md.bak.pre-houserules`, `scripts/jspace.py.bak.pre-houserules` in `~/.claude/skills/j-space/`. Discontinue if problems arise (user: trial run).

**Waydroid — Android container (2026-08-21, fully operational, GAPPS):** Session + container RUNNING, DHCP lease obtained, GAPPS images (system 2462.4M, vendor 535.5M). Persistence: `/var/lib/waydroid` and `~/.local/share/waydroid` both bind-mounted from `/persist`; `~/.Android`/`~/.android` symlinked to `~/Storage/`. tmpfs root stable at 3% (down from 100% before persistence — mistakes.md #13). Device registered for Play Store certification at google.com/android/uncertified; propagation in progress. Plain `waydroid` package in use, not `waydroid-nftables` (removed 2026-08-21 — was shadowing the system package on PATH, mistakes.md 2026-08-21 entry). **Structural ceiling:** hardware-backed (STRONG-tier) attestation apps (payment, banking, anti-cheat) cannot run under Waydroid — no TEE in a Linux container; not fixable (decisions.md #34). Full setup narrative archived (see archive_entries).
