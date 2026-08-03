{ pkgs, ... }:
{
  # Nix-on-Droid system layer (aarch64-linux, Android, no systemd, no Wayland).
  #
  # Nix-on-Droid is its own Android package (`com.termux.nix`) — a Termux fork,
  # NOT the Termux app. It gets its own sandbox at
  # /data/data/com.termux.nix/files, so it cannot see Termux's `$PREFIX` and it
  # is NOT an authorized caller for the Termux:API app (which allowlists
  # `com.termux`). The phone-agent MCP server therefore stays where it is, in
  # Termux, and is reached over the network (Tailscale, or 127.0.0.1 — loopback
  # works between Android apps). See droid/README.md.

  # The app's built-in font has no Nerd Font glyphs, so starship's powerline
  # separators and icons render as tofu. `terminal.font` takes a path to a font
  # file and installs it as ~/.termux/font.ttf (any pre-existing file is backed
  # up to font.ttf.bak). Same family volnix uses — see home/pkgs.nix.
  terminal.font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf";

  environment.packages = with pkgs; [
    # Minimal system floor. Everything else is user-scoped via home-manager
    # below, which nix-on-droid folds into environment.packages anyway
    # (home-manager.useUserPackages defaults on for stateVersion >= 20.09).
    procps
    util-linux
    hostname
    which
    curl
    openssh
  ];

  # Rename pre-existing /etc files instead of aborting the activation.
  environment.etcBackupExtension = ".bak";

  # Read the nix-on-droid changelog before changing this value.
  system.stateVersion = "24.05";

  # Same login shell as volnix. Must be a path to the exact binary.
  user.shell = "${pkgs.fish}/bin/fish";

  time.timeZone = "America/New_York";

  # Termux-compat shims (termux-open, termux-setup-storage, termux-wake-lock,
  # xdg-open, am). All default to false and are DELIBERATELY LEFT OFF.
  #
  # Enabling any of them pulls `termux-am`, which is one of nix-on-droid's own
  # packages — built from source with cmake, not a nixpkgs package. Upstream
  # publishes it prebuilt on nix-on-droid.cachix.org, but only against UPSTREAM'S
  # pinned nixpkgs, so our derivation hash does not match and the phone must
  # compile it. It cannot. Measured 2026-08-03 at the nixos-25.11 pin:
  #
  #   Running phase: unpackPhase
  #   cp: setting permissions for 'source': No such file or directory
  #   do not know how to unpack source archive /nix/store/...-source
  #
  # proot cannot set permissions on a directory it just created, so nixpkgs'
  # `unpackFile` (`cp -pr --reflink=auto`) dies on any directory source. Same
  # class as tar's "Cannot change mode ..." that killed sqlalchemy-bigquery.
  #
  # Two fixes were tried on-device and BOTH FAILED — do not retry them:
  #
  #   1. The nixos-25.11 pin. The old note here guessed that giving nix-on-droid
  #      its own nixpkgs would make upstream's cachix builds match again. It does
  #      not: upstream pins its own rev, not a release channel. Verified — the
  #      resulting path 404s on nix-on-droid.cachix.org, cache.nixos.org AND
  #      cache.numtide.com.
  #   2. `overrideAttrs` with `cp -r --no-preserve=mode,ownership`. Identical
  #      failure: cp sets the mode on directories it creates regardless.
  #
  # The remaining route is to build it somewhere that is not proot and copy the
  # closure in — `boot.binfmt.emulatedSystems = [ "aarch64-linux" ]` on volnix,
  # then `nix copy`. It is a tiny C program, so emulation is cheap here.
  #
  # Cost of leaving this off: no `xdg-open`/`termux-open-url`, so `claude` cannot
  # launch a browser for OAuth — press `c` at its prompt to copy the URL instead
  # (hand-selecting it clips the leading `h` at this terminal width). Also no
  # `termux-wake-lock`, which will matter for long-running agents on the phone.
  # android-integration = { ... };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      # The phone builds nothing it can avoid building.
      fallback = true
    '';

    # `nix.substituters` / `nix.trustedPublicKeys` are `listOf str` and
    # nix-on-droid sets cache.nixos.org + nix-on-droid.cachix.org in its own
    # `config` block, so these APPEND rather than replace.
    #
    # Kept although droid/agents.nix no longer installs any `pkgs.llm-agents.*`
    # package. At the nixos-25.11 pin this cache cannot match those paths anyway
    # (its builds are keyed to llm-agents' own nixpkgs — that is exactly why the
    # set was dropped), so it currently costs one extra 404 per substitution
    # query and buys nothing. It stays only so the entry is here, correct and
    # signed, if the pin ever lifts. Delete it if the query latency annoys you.
    # Key taken from llm-agents.nix's own `nixConfig`.
    substituters = [ "https://cache.numtide.com" ];
    trustedPublicKeys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;
    config = import ./home.nix;
  };
}
