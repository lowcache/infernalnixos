{ pkgs, nix-on-droid, ... }:
{
  # The upstream android-integration module calls pkgs.callPackage directly on
  # the termux-am/termux-tools derivation files, bypassing pkgs.termux-am from
  # our overlay. Disable it and load our replacement (./android-integration.nix)
  # which goes through the overlay so prootUnpack takes effect.
  disabledModules = [ "${nix-on-droid}/modules/environment/android-integration.nix" ];
  imports = [ ./android-integration.nix ];
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

  # termux-am and termux-tools are overridden in droid/backports.nix with
  # `prootUnpack`, which fixes the fetchFromGitHub directory-source cp failure
  # under proot that previously blocked these shims. See backports.nix for the
  # full problem description and fix.
  android-integration = {
    xdg-open.enable = true; # `claude` calls xdg-open for OAuth browser flow
    termux-wake-lock.enable = true; # prevent sleep during long agent sessions
    termux-wake-unlock.enable = true;
  };

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
