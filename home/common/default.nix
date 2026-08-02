{
  # Portable Home Manager layer.
  #
  # Everything here must evaluate on ANY platform Home Manager supports — no
  # Wayland/niri/Noctalia, no systemd units, no sops-nix `/run/secrets`, no
  # `/persist` impermanence paths, no hardware assumptions. Host-specific
  # additions layer on top by merging into the same options:
  #
  #   volnix (x86_64 NixOS desktop) -> home/shell.nix + home/pkgs.nix
  #   nix-on-droid (aarch64 Android) -> droid/home.nix
  #
  # `programs.fish.{shellInit,interactiveShellInit}` are `types.lines` and
  # `shellAliases`/`functions`/`home.packages` merge, so each host appends its
  # own without redefining anything shared.
  imports = [
    ./fish.nix
    ./tools.nix
    ./packages.nix
  ];
}
