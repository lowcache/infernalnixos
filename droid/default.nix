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

  # Termux-compat shims. These work by broadcasting Android intents at
  # nix-on-droid's OWN package, so they are independent of the Termux app.
  android-integration = {
    am.enable = true;
    termux-open.enable = true;
    termux-open-url.enable = true;
    termux-setup-storage.enable = true;
    termux-reload-settings.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    xdg-open.enable = true;
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
