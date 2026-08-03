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
  # publishes it prebuilt on nix-on-droid.cachix.org, but only against
  # UPSTREAM'S pinned nixpkgs. Because this flake points nix-on-droid at our
  # nixpkgs (the whole point: one package set for phone and laptop), the derivation
  # hashes differ, the cachix build no longer matches, and the phone has to
  # compile it locally. That fails under proot:
  #
  #   Running phase: unpackPhase
  #   cp: setting permissions for 'source': No such file or directory
  #   do not know how to unpack source archive /nix/store/...-source
  #
  # Same class of failure as tar's "Cannot change mode ..." — proot cannot set
  # permissions on freshly created files during unpack. It is not fixable from
  # here, and it is the cost of sharing one nixpkgs.
  #
  # To get these back, either accept a second nixpkgs for nix-on-droid (drop the
  # `nixpkgs.follows`, so its cachix builds match again), or wait for an
  # upstream aarch64 build against a newer nixpkgs.
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
    # Without cache.numtide.com the llm-agents packages in droid/agents.nix have
    # no substitute and the phone compiles every one of them from source. The
    # key is taken from llm-agents.nix's own `nixConfig`.
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
