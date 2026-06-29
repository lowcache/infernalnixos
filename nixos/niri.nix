# nixos/niri.nix — niri compositor + Noctalia v5 desktop enablement.
{ ... }:
{
  # Scrollable-tiling Wayland compositor (nixpkgs 25.11). Registers niri.desktop,
  # the sole graphical session (launched via uwsm from greetd; see configuration.nix).
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
