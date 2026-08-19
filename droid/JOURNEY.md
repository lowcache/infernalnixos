# Nix-on-Droid: The Rigamaroll

Curated narrative of the full effort of getting `nix-on-droid` to share a flake
with the desktop `volnix` config. Each act is a self-contained mystery + fix, so
the outline doubles as a lookup index when a specific piece of the story is
needed.

---

## Hook / Opening

- "I put NixOS on my phone. Or tried to."
- One flake, one `flake.lock`, shared `home/common/` between desktop and phone.
  `nixOnDroidConfigurations.default` alongside `nixosConfigurations.volnix`.
  Should Just Work™.
- Foreshadow: it did not.

---

## Act 1 — The Hang That Wasn't a Hang

### 1.1 Symptom

- First `nix-on-droid switch` completes clean. MOTD prints. Cursor blinks.
  Forever.
- No CPU spike, no OOM. Just no prompt.

### 1.2 The blind test

```bash
# Typed blind into what looked like a dead terminal:
echo hi > /sdcard/x
# From the laptop:
adb shell cat /sdcard/x    # -> hi
```

- Shell was alive the whole time. Silently reading commands and executing with
  no prompt.

### 1.3 Bidirectional debug channel

```bash
adb push probe.sh /data/local/tmp/
# In the app (blind):
bash /android/data/local/tmp/probe.sh > /android/sdcard/out.txt 2>&1
adb shell cat /sdcard/out.txt
```

- `/proc/<pid>/stat` fields 5 (`pgrp`) vs 8 (`tpgid`) to tell "hung" from "in a
  background process group."
- Trap: wrapping a test in `timeout` creates a fresh pgrp and manufactures that
  false positive. Use `timeout --foreground`.

### 1.4 The proof

```
ioctl TCGETS  0x5401      OK
ioctl TCGETS2 0x802C542A  EACCES
tty (coreutils 9.5,  glibc 2.40) -> /dev/pts/0
tty (coreutils 9.11, glibc 2.42) -> not a tty
python3.14 (glibc 2.42): os.isatty(0) -> False
```

Same fd, same instant, two glibcs, opposite answers.

### 1.5 Root cause

- glibc 2.42 reimplemented `isatty()` / `tcgetattr()` on top of the **`TCGETS2`**
  ioctl (termios2, arbitrary baud rates).
- Android's SELinux ioctl allowlist for `untrusted_app` permits `TCGETS` but not
  `TCGETS2`. On-device: `EACCES`.
- Every glibc-2.42 binary concludes it has no terminal. bash/fish start
  non-interactive, print no prompt, silently read from the pty.

### 1.6 Fix: pin the phone

```nix
inputs = {
  nixpkgs.url            = "github:NixOS/nixpkgs/nixos-unstable";
  nixpkgs-droid.url      = "github:NixOS/nixpkgs/nixos-25.11";
  home-manager-droid.url = "github:nix-community/home-manager/release-25.11";
};

nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
  pkgs = import inputs.nixpkgs-droid { system = "aarch64-linux"; /* … */ };
  home-manager-path = inputs.home-manager-droid.outPath;
};
```

- Unpin only when glibc falls back to `TCGETS` when `TCGETS2` is refused.

---

## Act 2 — The Cache Miss You Can't Fix With A Substituter

### 2.1 Symptom

- After the pin: `nix-on-droid switch` announces ~40 source builds under proot.
  Died midway.

### 2.2 The trap

- `pkgs.llm-agents.*` ships pre-built to `cache.numtide.com`, but the cache is
  keyed to *numtide's own nixpkgs*. The 25.11 pin shifts every transitive hash.
  Every derivation misses. Cache serves nothing.

### 2.3 Prevention rule

> "Pinned in flake.lock" ≠ "a prebuilt exists in the cache."
> Overlays that add packages have a load-bearing dependency on the base nixpkgs
> version.

### 2.4 Fix

- Drop the overlay. Selectively backport what actually matters (rtk,
  mcp-gateway — Act 4).

---

## Act 3 — android-integration, Round 1 (Failed)

### 3.1 Why it matters

- `termux-open-url` / `xdg-open` for claude-code's OAuth browser handoff.
- `termux-wake-lock` for long agent sessions.

### 3.2 Symptom

```
building '/nix/store/…-termux-am-…drv'…
cp: cannot change ownership of '/…': Operation not permitted
```

### 3.3 Two attempts, both failed identically

1. Pin nix-on-droid itself to a release rev (hoping upstream cachix had the
   older hash). → Still 404s on cache.nixos.org, nix-on-droid.cachix.org,
   cache.numtide.com.
2. `overrideAttrs` replacing `cp -pr` with `cp -r --no-preserve=mode,ownership`.
   → `cp` still sets mode on directories *it creates*, regardless of flags.

### 3.4 Called closed, documented, moved on

- Manual OAuth copy-paste as the interim tradeoff. (Falls out for free in
  Act 5.)

---

## Act 4 — The Proot Unpack Problem, Solved For Real

### 4.1 The forcing function

- **`rtk`** (token-optimizing CLI proxy) and **`mcp-gateway`** (loopback for
  phone-agent MCP) — both unstable-only, both fetchFromGitHub, both hit the
  same failure.

### 4.2 Problem 1: `_defaultUnpack` chmods a directory it just created

```
cp: setting permissions for 'source': No such file or directory
```

Fix — never let cp create the destination:

```nix
prootUnpack = drv: drv.overrideAttrs (o: {
  sourceRoot = "source";
  preUnpack = (o.preUnpack or "") + ''
    _defaultUnpack() {
      local fn="$1"
      if [ -d "$fn" ]; then
        local destDir; destDir="$(stripHash "$fn")"
        mkdir -p "$destDir"
        cp -r --no-preserve=mode,ownership "$fn"/. "$destDir"/
        chmod -R u+w "$destDir"
      else
        case "$fn" in
          *.tar.gz|*.tgz) gzip -d < "$fn" | tar xf - --warning=no-timestamp ;;
          # … other archive types
        esac
      fi
    }
  '';
});
```

### 4.3 Problem 2: Cargo's vendor hook bypasses unpackFile

- `cargoSetupPostUnpackHook` runs
  `cp -Lr --reflink=auto -- "$cargoDeps" "$dest"` directly. Same trap.
- Fix — take the hook's other branch by setting `cargoVendorDir` (inert on
  non-cargo derivations), and stage the vendor tree yourself:

```nix
cargoVendorDir = "vendor";
postUnpack = ''
  if [ -n "''${cargoDeps-}" ]; then
    mkdir -p source/vendor
    cp -r --no-preserve=mode,ownership "$cargoDeps"/. source/vendor/
    chmod -R u+w source/vendor
  fi
'' + (o.postUnpack or "");
```

### 4.4 Bonus: rustc version mismatch

- `mcp-gateway` needs rustc 1.95; 25.11 ships 1.91.1.

```nix
newerRust = final.makeRustPlatform {
  inherit (unstablePkgs) rustc cargo;
};

mcp-gateway = prootUnpack (
  fromUnstable "/pkgs/by-name/mc/mcp-gateway/package.nix" {
    rustPlatform = newerRust;
  }
);
```

- Keeps pinned stdenv/cc → binary still links glibc 2.40. Glibc-2.42 rustc
  running during build is harmless (TCGETS2 only breaks terminal detection,
  rustc doesn't care).

---

## Act 5 — android-integration, Round 2 (Worked)

### 5.1 Free win

- Apply `prootUnpack` to `termux-am` and `termux-tools`. Build succeeds.

### 5.2 New wrinkle: upstream module bypasses the overlay

- Upstream does `pkgs.callPackage ./pkgs/termux-am.nix { }` — builds fresh,
  overlay never consulted.

### 5.3 Fix: disable upstream, replace with a module that reads from `pkgs.*`

```nix
# droid/default.nix
{ pkgs, nix-on-droid, ... }: {
  disabledModules = [
    "${nix-on-droid}/modules/environment/android-integration.nix"
  ];
  imports = [ ./android-integration.nix ];

  android-integration = {
    xdg-open.enable         = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
  };
}
```

```nix
# droid/android-integration.nix — same options, reads pkgs.termux-am / pkgs.termux-tools
{ config, lib, pkgs, ... }:
let cfg = config.android-integration;
    ifD = cond: pkg: if cond then [ pkg ] else [ ];
in {
  options.android-integration = { /* same options as upstream */ };
  config.environment.packages =
       (ifD cfg.am.enable                pkgs.termux-am)
    ++ (ifD cfg.xdg-open.enable          pkgs.termux-tools.xdg_open)
    ++ (ifD cfg.termux-wake-lock.enable  pkgs.termux-tools.wake_lock);
}
```

### 5.4 Wiring

```nix
# flake.nix
extraSpecialArgs = { nix-on-droid = inputs.nix-on-droid; };
```

---

## Act 6 — Papercuts

### 6.1 Nerd Font tofu

```nix
terminal.font =
  "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf";
```

### 6.2 numtide cache trust bootstrap (before first switch)

```bash
mkdir -p ~/.config/nix
curl -sfL https://raw.githubusercontent.com/lowcache/volnixos/main/droid/nix.conf \
  -o ~/.config/nix/nix.conf
```

- Skipping this warns `ignoring substitute … because it's not signed`, falls
  back to source, dies later on a package that can't be unpacked under proot.

### 6.3 `--impure` is required

- Upstream references `proot-termux` via `builtins.storePath` (pure eval
  rejects it).

---

## Payoff

- claude-code's Ink/React TUI renders in full color on the phone — the exact
  class of program `TCGETS2` was strangling.
- 820 packages, zero on-device source builds after the initial `prootUnpack`
  cost.
- Shared `home/common/` layer byte-identical to desktop.
- claude-code, codex, opencode, rtk, mcp-gateway on `$PATH`;
  android-integration for OAuth; wake-lock for long sessions.

## Lessons

1. When a terminal "hangs," redirect stdout before concluding anything. It
   might be talking to you.
2. "Cached" is a claim about a specific hash. Pin your base, every overlay's
   cache-key claim expires.
3. `overrideAttrs` doesn't help if the module doesn't consult your overlay.
4. Proot's isolation model is a real constraint on unpacking, not a bug to
   flag your way around.
5. `cargoVendorDir = "vendor"` is a free escape hatch when cargo's hook is
   copying things it shouldn't.
