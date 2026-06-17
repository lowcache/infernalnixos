# nixos/niri.nix — niri compositor + Noctalia v5 second-session enablement.
# Additive & reversible: delete this file and drop the ./niri.nix import from
# configuration.nix to fully revert. Hyprland/ii stays the default greeter session.
{ ... }:
{
  # Scrollable-tiling Wayland compositor (nixpkgs 25.11). Registers niri.desktop
  # as a selectable session alongside hyprland.desktop in the tuigreet menu.
  programs.niri.enable = true;

  # Noctalia v5 runtime deps (docs.noctalia.dev/v5/getting-started/nixos).
  # Both were absent from configuration.nix (audited 2026-06-17).
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  # services.power-profiles-daemon stays disabled (asusd owns power profiles on
  # this ASUS host); Noctalia's power-profile widget is optional and degrades.

  # NOTE (follow-up): for X11 apps under niri add pkgs.xwayland-satellite +
  # spawn-at-startup in dots/niri/config.kdl. Left out here to keep the change
  # minimal; native Wayland apps work without it.
}
