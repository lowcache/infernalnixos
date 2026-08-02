{ pkgs, ... }:
{
  # Home Manager layer for the phone. `home.username` and `home.homeDirectory`
  # are set by nix-on-droid's home-manager module — do not set them here.
  imports = [
    ../home/common
    # BISECT (2026-08-02): temporarily out. Activation dies in `installPackages`
    # with "getting pseudoterminal attributes: Permission denied" while building
    # user-environment.drv. Verified on-device that this is NOT a general proot
    # problem: trivial derivations build fine under both the old and new CLI, and
    # `nix profile install` of a small path builds its user-environment cleanly.
    # It only fails for the full ~500-package closure. Re-add once the minimal
    # closure activates, then bisect this list.
    # ./agents.nix
  ];

  home.stateVersion = "24.11";

  # The only non-trivial derivation the phone would otherwise build is Home
  # Manager's own reference manpage. `man home-configuration.nix` is a laptop
  # activity; skip the on-device render.
  manual.manpages.enable = false;

  # Phone-only shell surface. Merges into the shared fish config in
  # home/common/fish.nix; nothing there is redefined.
  programs.fish = {
    shellInit = ''
      # Nix-on-Droid lives in its own Android app sandbox. $PREFIX is the
      # Termux-style usr root; keep scratch inside it so it survives a
      # session restart and never lands on an unwritable Android path.
      set -gx TMPDIR $PREFIX/tmp
      test -d $TMPDIR; or mkdir -p $TMPDIR

      # Where the flake lives once cloned on-device.
      set -gx NIX_CONFIG_DIR $HOME/.nix-config
    '';
    shellAliases = {
      # Phone equivalents of the volnix rebuild aliases. There is no
      # `nixos-rebuild` here — nix-on-droid switch is the whole interface.
      droid-switch = "nix-on-droid switch --flake $NIX_CONFIG_DIR";
      droid-build = "nix-on-droid build --flake $NIX_CONFIG_DIR";
      droid-rollback = "nix-on-droid rollback";
      cfg = "cd $NIX_CONFIG_DIR";
    };
  };

  home.packages = with pkgs; [
    # Phone-side extras that make sense without a desktop session.
    fastfetch
    wget
    rsync
    unzip
    zip
    tmux
  ];
}
