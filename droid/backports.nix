# Backport overlay for the phone.
#
# The phone is pinned to nixos-25.11 (see droid/README.md — glibc 2.42's TCGETS2
# isatty() is refused by Android SELinux). Some tools lowcache depends on daily
# only exist in nixpkgs-unstable. Rather than re-package them, we `callPackage`
# unstable's own expression against the pinned package set: same recipe, built
# against glibc 2.40.
#
# Two Android-specific problems have to be solved to build anything from source
# on-device, and both are handled by `prootUnpack` below.
{
  unstable, # the nixpkgs-unstable SOURCE tree (for its package expressions)
  unstablePkgs, # unstable instantiated for aarch64 (for its newer rustc only)
  nix-on-droid-src, # nix-on-droid flake (for its pkg expressions — termux-am etc.)
}:

final: _prev:

let
  # ── Problem 1: proot cannot unpack a directory source ──────────────────────
  #
  # nixpkgs' `_defaultUnpack` copies a directory `src` with
  # `cp -pr --reflink=auto`. Under proot that dies:
  #
  #   cp: setting permissions for 'source': No such file or directory
  #
  # cp creates the destination directory and then chmods it, and proot returns
  # ENOENT for that chmod even though the directory exists. It is not about
  # preserving the source mode — `--no-preserve=mode,ownership` fails
  # identically, because cp still applies a default mode to directories it
  # creates. The fix is to never let cp create the destination: pre-make it and
  # copy the CONTENTS in. Verified on-device 2026-08-03 with a probe derivation.
  #
  # This affects every derivation whose src is a directory, which is every
  # fetchFromGitHub/fetchzip — it is why termux-am, sqlalchemy-bigquery and rtk
  # all failed identically.
  #
  # ── Problem 2: cargo's vendor hook does its own copy ───────────────────────
  #
  # `cargoSetupPostUnpackHook` does not route through unpackFile. It runs
  # `cp -Lr --reflink=auto -- "$cargoDeps" "$dest"` directly, so overriding
  # _defaultUnpack is not enough. That hook has a second branch: when
  # `cargoVendorDir` is set it points at a vendor tree already inside the source
  # and never copies at all. So we place the vendor tree ourselves in
  # `postUnpack` (which `runHook` fires BEFORE postUnpackHooks) and take that
  # branch.
  #
  # Assumes `sourceRoot = "source"`, which holds for the fetchers used here.
  prootUnpack =
    drv:
    drv.overrideAttrs (o: {
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
              *.tar.xz|*.tar.lzma|*.txz) xz -d < "$fn" | tar xf - --warning=no-timestamp ;;
              *.tar.gz|*.tgz|*.tar.Z)    gzip -d < "$fn" | tar xf - --warning=no-timestamp ;;
              *.tar.bz2|*.tbz2|*.tbz)    bzip2 -d < "$fn" | tar xf - --warning=no-timestamp ;;
              *.tar.zst)                 zstd -d < "$fn" | tar xf - --warning=no-timestamp ;;
              *.tar)                     tar xf "$fn" --warning=no-timestamp ;;
              *) return 1 ;;
            esac
          fi
        }
      '';

      # REQUIRED, and easy to drop by accident: without this the hook takes its
      # `cp -Lr` branch and fails with
      #   cp: setting permissions for '<pname>-<version>-vendor'
      # even though postUnpack below already staged the tree. Setting it on a
      # non-cargo derivation is an inert env var.
      cargoVendorDir = "vendor";

      postUnpack = ''
        if [ -n "''${cargoDeps-}" ]; then
          mkdir -p source/vendor
          cp -r --no-preserve=mode,ownership "$cargoDeps"/. source/vendor/
          chmod -R u+w source/vendor
        fi
      ''
      + (o.postUnpack or "");
    });

  # 25.11 ships rustc 1.91.1. mcp-gateway declares `rust-version = 1.95` and
  # cargo refuses to build below it. Borrow the newer compiler ONLY:
  # makeRustPlatform keeps the pinned stdenv and cc wrapper, so the produced
  # binary still links glibc 2.40 and keeps a working isatty(). Running a
  # glibc-2.42 rustc during the build is harmless — the TCGETS2 bug only breaks
  # terminal detection, and a compiler does not care.
  newerRust = final.makeRustPlatform { inherit (unstablePkgs) rustc cargo; };

  fromUnstable = path: args: final.callPackage (unstable + path) args;
in
{
  # Token-optimising CLI proxy. Rust; builds on-device in a few minutes.
  rtk = prootUnpack (fromUnstable "/pkgs/by-name/rt/rtk/package.nix" { });

  # The reason the phone is worth doing at all: it fronts the phone-agent MCP
  # server, so an agent running ON the phone reaches Termux:API over loopback
  # with no Tailscale hop. See droid/README.md.
  mcp-gateway = prootUnpack (
    fromUnstable "/pkgs/by-name/mc/mcp-gateway/package.nix" { rustPlatform = newerRust; }
  );

  # termux-am and termux-tools are NOT in the nix-on-droid overlay — they only
  # exist inside the android-integration module via pkgs.callPackage. We build
  # them fresh here from the nix-on-droid source so the overlay exposes them as
  # pkgs.termux-am / pkgs.termux-tools for our replacement module to use.
  # Both use fetchFromGitHub (directory source) and need prootUnpack.
  termux-am = prootUnpack (
    final.callPackage "${nix-on-droid-src}/pkgs/android-integration/termux-am.nix" { }
  );
  termux-tools = prootUnpack (
    final.callPackage "${nix-on-droid-src}/pkgs/android-integration/termux-tools.nix" {
      termux-am = final.termux-am;
    }
  );
}
