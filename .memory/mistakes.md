---
type: mistakes
project: Vol NixOS
last_updated: 2026-07-31
status: append-only
---

# Known Mistakes and Prevention Rules (`memory/mistakes.md`)

This file catalogs past bugs, configuration issues, and operational pitfalls encountered on **Vol NixOS**. AI agents must study these cases to prevent regression.

---

## 1. NixOS Rebuild Switched Graphical Session Logout & Process Termination

* **Incident (2026-06-01):** Running `sudo nixos-rebuild switch` from a terminal window (`kitty`) inside the graphical session (Hyprland) caused the graphical display manager (`greetd`) to restart due to package updates. 
* **The Bug:** The restart of `greetd` automatically logged the user out, closing all X11/Wayland clients, which instantly killed the parent terminal emulator process (`kitty`). This aborted the `nixos-rebuild switch` process mid-execution. 
* **Impact:** Services (such as `open-webui` and `ollama`) had already been stopped during the update transition but were left inactive (dead) because the switch process was killed before reaching their restart step.
* **Prevention Rule:** When major graphical system configurations, library dependencies (`glibc`), or session managers are changed, always warn the human developer before executing a switch. Recommend executing the switch via a systemd background task, systemd-run, or multiplexer (`tmux`/`screen`) to isolate the rebuild process from session terminations.

---

## 2. ASUS Shutdown Service Systemd Block

* **Incident (2026-06-01):** The `nixos-rebuild switch` process timed out and aborted (exit status `101`) during system activation because the `asus-shutdown.service` hung during its deactivation phase.
* **The Bug:** The systemd unit for `asus-shutdown.service` is configured with `SendSIGKILL=no`. When systemd attempts to stop the service, it sends a `SIGTERM` signal. The `asusctl` shutdown daemon intercepts `SIGTERM` and defers exit indefinitely waiting for safe system boundaries. Since systemd is prevented from sending `SIGKILL` to force-terminate it, the unit hangs forever until the systemd stop timeout is exceeded, failing the overall switch activation.
* **Impact:** Interrupted system builds, leaving other services (like `NetworkManager`) stopped and un-restored on boot.
* **Prevention Rule:** If `asus-shutdown` hangs, manually force-kill the untracked stale background daemon process (e.g., `sudo kill -9 <PID>`) and then start the new systemd unit to restore tracking.

---

## 3. Ollama Hybrid Nvidia GPU Battery Drain

* **Incident (2026-06-01):** The laptop experienced exceptionally high idle power draw and rapid battery depletion.
* **The Bug:** `pkgs.ollama-cuda` ran as a system boot service. Even when idle, it initialized the GPU drivers and held open descriptors on `/dev/nvidia*`. This blocked the Nvidia GPU from entering its runtime power suspend state (RTD3, 0W draw), forcing it to stay active at 42W power usage.
* **Prevention Rule:** Always ensure Ollama is configured with `"OLLAMA_KEEP_ALIVE=5m"` (or shorter) in its service environment variables. This forces Ollama to unload models and release all active CUDA handles to the discrete GPU after a period of inactivity, letting the driver power off the card completely.

---

## 4. Fooocus Symlink Path and Folder Name Typos

* **Incident (2026-06-01):** The out-of-store symlink mapping for Fooocus outputs resolved to a broken target path, preventing user access to generated images.
* **The Bug:** The directory name in `home/persist.nix` contained a typographical error (`ai-generatiobn` with an extra 'b') while the actual directory created in `nixos/configuration.nix` was named `/home/lowcache/Storage/ai-generation`. Additionally, the symlink key itself contained a spelling mismatch (`ouputs` instead of `outputs`).
* **Prevention Rule:** Double-check directory declarations against `/persist` boundaries. Ensure Home Manager out-of-store paths and NixOS system tmpfiles rules utilize identical spelling profiles.

---

## 5. Shell Function/Alias Syntax Errors in `home/shell.nix`

* **Incident (2026-06-01):** Audit found three silent defects in the fish config that never error at build time but fail at runtime.
* **The Bugs:**
  * `setwall`: `ln - sf "$img" ...` — the space split `-` and `sf` into separate args, so the symlink update always failed.
  * `clear` alias: `printf '033[...'` — the octal ESC was missing its backslash, so it printed literal `033[...` instead of clearing. Note: Nix double-quoted strings eat a lone backslash, so the fix must be `\\033` to emit `\033` to fish.
  * `forggo`/`forgstp` aliases targeted `docker-forge.service`, which is not declared (only the `fooocus` oci-container exists). Commented out pending a forge container.
* **Prevention Rule:** Shell strings embedded in Nix are not validated by `nix flake check` — they only fail when invoked. When editing `home/shell.nix`, mentally run each alias/function, and remember to double-escape backslashes (`\\`) for any escape sequence that must survive into the shell.

---

## 6. Nvidia Driver/Library Version Mismatch on System Switch

* **Incident (2026-06-05):** Running `make switch` upgraded user-space Nvidia libraries to `595.80`, but the systemd service `nvidia-container-toolkit-cdi-generator.service` failed to start with a driver/library version mismatch error (`failed to initialize NVML: Driver/library version mismatch`).
* **The Bug:** The kernel was still running the older Nvidia driver module (`595.71.05`), while the newly built user-space packages/libraries (such as `libnvidia-ml.so`) were compiled/linked for `595.80`. Since NVML requires matching driver and user-space library versions, any service invoking NVML (like the CDI generator) fails to initialize and exits with error code 1.
* **Prevention Rule:** A reboot is required to load the newly built kernel module and match the updated user-space libraries. Alternatively, if a reboot is not currently possible and container GPU access is not immediately required, the service failure can be ignored until the next boot.

---

## 7. Lix Rebuilt From Source Every Switch (binary cache silently missed)

* **Incident (2026-06-08):** Every `nixos-rebuild` recompiled **Lix** from source (the heaviest build of the switch) despite `cache.lix.systems` being configured as a substituter with its trusted public key, and `lowcache` being in `trusted-users`. Effective `nix config show` confirmed all substituters/keys were live.
* **The Bug:** The `lix-module` flake input carried two overrides — `inputs.nixpkgs.follows = "nixpkgs"` **and** `inputs.lix.url = "git+https://git.lix.systems/lix-project/lix"` (no rev → tracked `main`, locked to `daa2bc82`). The `follows` rebuilt Lix against our *top-level* nixpkgs, and the url override pinned Lix to a bleeding `main` commit. Either change shifts the Lix derivation hash away from what `cache.lix.systems` built (Lix's *own* pinned lix × its *own* pinned nixpkgs), so no substitute exists → source build. Key lesson: **"pinned in flake.lock" ≠ "a prebuilt exists in the cache."** A correct substituter list does nothing if the derivation hash doesn't match.
* **Attempted "fix" that BACKFIRED — do NOT repeat:** Removed both overrides and ran `nix flake update lix-module`. `lix-module` `727d859b` expects **Lix 2.96**, but with the override gone its own `lix` input resolved to `91867941` = **2.94.0-pre** (older). That version desync, plus that older Lix referencing **`mdbook-linkcheck`** (removed from current nixpkgs at mdbook 0.5.0+), made `nixos-rebuild` abort at *evaluation*: `error: 'mdbook-linkcheck' has been removed`. A slow-but-working setup became a broken one.
* **Recovery (2026-06-08):** `git checkout fb63b6f -- flake.nix flake.lock` — the last commit that actually built the banner: original lix-module block (follows + `inputs.lix.url` tracking main), `lix=daa2bc82`, `infernal-init=9862dd2`. Confirmed working with `nix eval ~/.nix-config#nixosConfigurations.volnix.config.system.build.toplevel.drvPath` returning a `.drv` *before* rebuilding.
* **Prevention Rules:**
  1. The `follows`/`lix.url` overrides are **load-bearing** here — `lix-module 727d859b` tracks `lix` main, so removing the override exposes the module's own older, incompatible lix pin. Don't strip them casually.
  2. `cache.lix.systems` only serves **tagged releases**. While `inputs.lix.url` tracks `main`, Lix will **always** build from source — that cache miss is inherent to main-tracking, *not* caused by the follows. Removing the follows alone does not earn a cache hit.
  3. To genuinely hit the cache you must pin **both** `lix-module` and `lix` to a matched *release* that also builds against current nixpkgs — a deliberate, separately-tested change, not a quick edit.
  4. **NEVER** alter Lix pinning without eval-verifying (`nix eval …toplevel.drvPath`) before triggering a rebuild. A slow source build is acceptable; a broken eval that aborts the switch is not.
  5. (Unrelated) `nil` source rebuilds are `pkgs.nil` from nixpkgs hitting cache.nixos.org lag for a fresh rev — not a config defect; resolves when Hydra catches up.

---

## 8. Live Credentials Committed to a PUBLIC GitHub Repo (blanket-tracked `.gemini`)

* **Incident (2026-06-09):** `dots/gemini/oauth_creds.json` (Google OAuth tokens), `google_accounts.json`, and agent task-logs under `antigravity-cli/brain/` (which captured live secrets) were committed and pushed to the **public** repo `github.com/lowcache/volnixos` (commit `2ccdd52 "added .gemini to dots"`). Confirmed public via anonymous GitHub API (HTTP 200).
* **The Bug:** `.gemini` was added to `dots/` wholesale (out-of-store symlinked **and** git-tracked) "to keep a working config." Two compounding errors: (a) the out-of-store symlink already serves the live config from disk + `/persist`, so git tracking was never required for it to work; (b) the intended guard `dots/gemini/.gitignore` was non-functional — its patterns were written repo-root-relative (`dots/gemini/oauth_creds.json`) inside a file that interprets paths relative to its **own** directory, so they matched nothing, and gitignore cannot untrack already-committed files regardless. 159 MB / 1058 files of agent chaff (`brain/ mcp/ log/ cache/ tmp/ history/`) rode along, including logs the agent had written secrets into.
* **Impact:** Plaintext OAuth tokens exposed on a public repo. (`nixos/secrets.yaml` was safe — sops-encrypted.) Tokens must be treated as fully compromised.
* **Remediation done (2026-06-09):** `git rm -r --cached` of 615 secret/chaff files (left on disk; live config untouched, 1058→443 tracked); rewrote `dots/gemini/.gitignore` with correct dir-relative patterns (keep `config/ skills/ settings.json GEMINI.md mcp_config.json`; ignore `brain/ mcp/ log/ cache/ tmp/ history/ *.log oauth_creds.json google_accounts.json state.json installation_id`); verified with `git check-ignore`.
* **STILL OPEN — NOT resolved:**
  1. **Rotate** the Google/Gemini OAuth tokens (+ any API key Antigravity touched in logged sessions). The ONLY action that un-exposes them; untracking/scrub cannot.
  2. **History scrub** — secrets remain in every historical commit on `origin/main`. Needs `git filter-repo --invert-paths` + `git push --force` before the repo is clean.
* **Prevention Rules:**
  1. Secrets NEVER live under `dots/` (public repo). Use sops (encrypted, committable) or `/persist` (never tracked). See decisions.md #5.
  2. Never blanket-track agent/tool dirs (`.gemini`, `.claude`, …) — they write credentials and verbose logs. Track only declarative config; the *symlink*, not git, is what makes the live config work.
  3. `.gitignore` patterns are relative to the file's own directory; verify with `git check-ignore <path>`.
  4. gitignore does not untrack committed files — pair every ignore rule for an already-tracked secret with `git rm --cached`.

---

## 9. Broken File Chooser Dialogs (XDG Desktop Portal Misconfiguration)

* **Incident (2026-06-10):** Brave Browser and other applications failed to launch a file chooser dialog when attempting to open or save files.
* **The Bug:** Three factors broke the portal: (a) `xdg.portal` config in `configuration.nix` lacked `config.common.default = "*"`, meaning the portal service could not resolve which backend to fall back to under Hyprland; (b) the environment was missing `GTK_USE_PORTAL = "1"`, which is necessary to force GTK/Electron apps to route file picker dialogs to D-Bus; (c) the portal service itself couldn't resolve base GNOME/GTK icons because `adwaita-icon-theme` and `hicolor-icon-theme` were not installed system-wide.
* **Prevention Rule:** When setting up a Wayland compositor (like Hyprland) on NixOS, always explicitly configure a default portal backend (`config.common.default = "*"`), include basic icon themes (`adwaita-icon-theme`, `hicolor-icon-theme`) in `environment.systemPackages`, and export `GTK_USE_PORTAL = "1"` in user session variables to guarantee GTK/Electron dialogue capability.
* **Correction (2026-06-09, supersedes the above as the actual root cause):** The portal backend/icon/`GTK_USE_PORTAL` changes did NOT fix it. See Mistake #10.

---

## 10. XDG Portal Rejects EVERY Call: dbus-broker pidfd vs xdg-desktop-portal app-id (THE real file-chooser/download bug)

* **Incident (2026-06-09):** Brave file chooser never opened and downloads never initiated. Console showed `Gdk-WARNING: Failed to read portal settings: GDBus.Error:org.freedesktop.DBus.Error.AccessDenied: Portal operation not allowed: Unable to open /proc/<pid>/root`. (kwallet/UPower lines in the same log were unrelated noise.)
* **Root Cause (proven; it is an upstream portal bug, NOT kernel-specific):** Upstream issue flatpak/xdg-desktop-portal#1953 — the portal opens the `/proc/<pid>/root` magic symlink with `O_RDONLY | O_NOFOLLOW`, which by POSIX *always* returns `ELOOP` on a symlink, so registration of any unsandboxed app fails with `Could not register app ID: Unable to open /proc/<pid>/root`. The portal then rejects EVERY request (Settings, FileChooser, ...) with `AccessDenied`. This buggy open is on the **pidfd code path**, taken only when the session bus passes peer credentials via pidfd (`ProcessFD`) — i.e. **dbus-broker**. The reference `dbus-daemon` passes no pidfd, takes the plain-open path, and the identical portal binary works. The 7.0.11-cachyos kernel is irrelevant (the bug reproduces on any kernel). Affected: xdg-desktop-portal **1.20.4 and earlier 1.20.x / 1.21.0**; fixed upstream (issue closed "completed"; `main` no longer uses `O_NOFOLLOW`). **nixpkgs unstable AND 26.11 still ship 1.20.4**, so no fixed build is available from the channel as of 2026-06 — the dbus-daemon switch is the only available fix without overlaying a newer portal yourself.
* **How it was proven:** (1) `gdbus call ... org.freedesktop.portal.Settings.ReadAll` reproduced the exact error against the live bus for ANY client (the failing pid was gdbus's own). (2) The SAME portal binary run under `dbus-run-session` (reference dbus-daemon) returned full results — no error. (3) Ruled OUT: cross-uid /proc (lowcache is uid 1001, portal+clients all 1001), hidepid (none), Landlock/seccomp/ProtectProc on the portal (NoNewPrivs=0, no seccomp, host namespaces), stale instance (fresh portal restart still failed; `dbus-broker` `NRestarts=0`, never desynced), and the giant `--max-*` broker limits (those are normal for a trusted session bus).
* **Fix:** `services.dbus.implementation = lib.mkForce "dbus";` in `nixos/configuration.nix`. `mkForce` is REQUIRED because `programs.uwsm` (the module behind `uwsm start hyprland.desktop`) forces this option to `"broker"` — that is why the session was on dbus-broker in the first place. Switches the session bus to the reference daemon whose no-pidfd path the portal handles correctly.
* **Prevention Rule:** If GTK/Electron file pickers or portal Settings fail with `AccessDenied` / `Unable to open /proc/<pid>/root`, do NOT chase portal backends, icons, or `GTK_USE_PORTAL`. Reproduce with `gdbus call --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop --method org.freedesktop.portal.Settings.ReadAll '[]'`; if it errors, the app-id step is broken. Compare against `dbus-run-session -- <same call>`. If the daemon works and the live broker bus does not, set `services.dbus.implementation = "dbus"`.
* **Rebuild caution:** Switching the dbus implementation restarts the message bus on `switch` and will tear down the running Wayland session (see Mistake #1). Apply via reboot, or run the rebuild detached (tmux / `systemd-run`).

### 2026-07-28 — niri 26.04 / libdisplay-info-sys 0.3.0: C-library Version Cap Skew

**Symptom:** `niri 26.04` build failed with `error: Requested 'libdisplay-info < 0.4.0' but version of libdisplay-info is 0.4.0`.

**Root cause:** niri 26.04 vendors the Rust crate `libdisplay-info-sys v0.3.0`, which hard-caps the C library at `< 0.4.0` (crate version is pinned, C lib is vendored through it). This nixpkgs commit bumped `libdisplay-info` from 0.3.x to 0.4.0 in the nixpkgs channel, but niri's vendored crate had not been updated to match. The build was invoked with `libdisplay-info 0.4.0` on the PATH (via `buildInputs`), and the crate's `build.rs` CMake configure step checked the `libdisplay-info.pc` version, found 0.4.0 (rejected by `< 0.4.0`), and aborted. Pure nixpkgs/flake-update skew — the C-lib bump outran its crate consumers.

**Prevention rule:** When Rust crate-based builds fail with version constraints on C libraries (e.g., "Requested 'libdisplay-info < 0.4.0' but version is 0.4.0"), the crate is likely vendored or pinned to an older version. Check the crate's `Cargo.toml` version constraint (not the package's Cargo.lock, which is stale at build time — nixpkgs *regenerates* it at eval/build). If the crate is truly pinned and won't accept the C lib version, pin the C lib to match the crate's constraint via an overlay for that package only. Verify by confirming the build cache-hits (Hydra already cached the niri build with the matching C lib), proving the pairing is correct and stable upstream.

**Revert condition:** Once nixpkgs upgrades niri to a version whose vendored crates accept `libdisplay-info >= 0.4.0`, or once the C lib is downgraded, remove the overlay and retry the build.

### 2026-07-31 — Stale OPENSSL_DIR Fish Variable Broke openssl-sys Cargo Builds

**Symptom:** Cargo install of lonkero failed during compilation: `error: 'libdir … does not contain the required files'` during the openssl-sys build phase.

**Root cause:** Fish universal variable `OPENSSL_DIR=/nix/store/…-openssl-3.6.3-dev/` was set (likely by hand at some point, not in Nix config — `grep -rn OPENSSL_DIR` across flake.nix and home/*.nix found nothing). The `openssl-sys` Rust crate checks `OPENSSL_DIR` first during build; if set, it bypasses pkg-config entirely and looks for shared libraries directly in that directory. The `.dev` output contains headers and `openssl.pc` but NO shared libraries (`.so` files). When openssl-sys found the libdir lacked the required shared libs, it panicked with exactly that error.

**Secondary issue:** Even after removing the stale env var and rebuilding, the binary's RPATH was `/nix/store/…-shell/lib` (from the throwaway `nix-shell` environment), so it failed at runtime: `libssl.so.3: cannot open shared object file: No such file or directory`. The linked binary had a transient RPATH pointing into a garbage-collected directory.

**Prevention rules:**
1. Never set `OPENSSL_DIR` environment variable, especially not to `.dev` outputs. The pkg-config mechanism resolves openssl correctly on its own (`nix-shell -p pkg-config openssl` auto-exposes it via pkg-config's setup hook).
2. For cargo installs of crates needing openssl at build time, always stamp a persistent RPATH via: `RUSTFLAGS="-C link-arg=-Wl,-rpath,/run/current-system/sw/share/nix-ld/lib" nix-shell -p pkg-config openssl --run 'cargo install <crate>'`. The `/run/current-system/sw/share/nix-ld/lib` directory is stable across boots and GC because it is populated by `programs.nix-ld.libraries` in `nixos/configuration.nix`. As long as the libraries list contains `openssl.out` (it does at line 288), that directory will contain `libssl.so.3` and `libcrypto.so.3`.
3. If `OPENSSL_DIR` or similar persistent environment-variable pins exist in `~/.config/fish/fish_variables`, `.bashrc`, `.zshrc`, or similar shell state files, inspect them regularly. Stale store paths will break builds and prevent Nix garbage collection of their targets. Use `set -Ue VARNAME` in fish or `unset VARNAME` in bash/zsh to clear them permanently.
4. The pattern `nix-shell` (not `nix shell`) is mandatory — only the former runs pkg-config's setup hook to expose the dev output. `nix shell` (flake-based, newer) does not.

**Applied fix (2026-07-31):** (1) Cleared the fish universal variable: `set -Ue OPENSSL_DIR`. (2) Rebuilt lonkero with the RUSTFLAGS + nix-shell pattern. (3) Verified the binary now links cleanly to the stable nix-ld lib directory: `ldd ~/.cargo/bin/lonkero | grep libssl` → `libssl.so.3 => /run/current-system/sw/share/nix-ld/lib/libssl.so.3`. (4) Confirmed runtime: `lonkero --version` prints `3.5.0`. The binary now persists across tmpfs wipes because the RPATH points to a durable location.
