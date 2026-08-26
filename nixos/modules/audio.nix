# Audio stack. PipeWire is otherwise switched on implicitly by nixpkgs'
# services/misc/graphical-desktop.nix (mkDefault), which leaves the whole stack
# — session manager, pulse compat, Bluetooth codec policy — outside this repo's
# control. This module takes ownership of it so those knobs are declarable.
#
# Machine-specific values (which ALSA cards to park) live in ../hosts/<name>.nix;
# this file only says how the feature works.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vol.audio;
in
{
  options.vol.audio = {
    enable = lib.mkEnableOption "PipeWire/WirePlumber audio owned by this repo";

    pulseTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install the PulseAudio *client* tools (`pactl`, `pacmd`) alongside the
        PipeWire pulse shim. The daemon stays off — `services.pulseaudio.enable`
        is untouched — but without this package there is no CLI able to list or
        switch sinks, leaving `wpctl` as the only lever.
      '';
    };

    parkedCards = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "alsa_card.pci-0000_01_00.1" ];
      description = ''
        ALSA `device.name` values to force to the "off" profile. Cards left on
        `pro-audio` publish one sink per PCM, which buries the real outputs in
        any selector. `device.profile` takes absolute priority in WirePlumber's
        find-best-profile hook, but a profile already recorded in
        `~/.local/state/wireplumber/default-profile` is resolved earlier and
        wins, so clear that file once when first parking a card.
      '';
    };

    bluetooth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.hardware.bluetooth.enable;
        defaultText = lib.literalExpression "config.hardware.bluetooth.enable";
        description = ''
          Apply the Bluetooth audio policy below. Follows the hardware switch
          (set in ../hardware-configuration.nix) rather than redeclaring it,
          since Bluetooth is not solely an audio concern.
        '';
      };

      codecs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "ldac"
          "aptx_hd"
          "aptx"
          "aac"
          "sbc_xq"
          "sbc"
        ];
        description = ''
          A2DP codecs offered to a headset, best first. The pipewire package in
          this closure ships the codec plugins for all of these (fdk-aac,
          libldacBT, libfreeaptx); a device still negotiates the best one it
          actually advertises, so the tail of the list is the real floor.
        '';
      };

      autoswitchToHeadsetProfile = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          WirePlumber's default (true) drops a headset from A2DP to HFP the
          moment any application opens a capture stream — a browser tab holding
          the mic is enough to collapse playback to narrowband mono until it
          lets go. Off keeps the headset in A2DP unconditionally, which also
          means its mic is not offered; capture falls to the built-in input.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # Overrides graphical-desktop.nix's mkDefault block so the stack is
        # declared here rather than inherited as a side effect of having a
        # graphical session at all.
        services.pipewire = {
          enable = true;
          audio.enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          wireplumber.enable = true;
        };

        # Realtime scheduling for the audio threads; not set by the implicit
        # graphical-desktop path.
        security.rtkit.enable = true;
      }

      (lib.mkIf cfg.pulseTools {
        environment.systemPackages = [ pkgs.pulseaudio ];
      })

      (lib.mkIf (cfg.parkedCards != [ ]) {
        services.pipewire.wireplumber.extraConfig."52-park-cards" = {
          "monitor.alsa.rules" = map (name: {
            matches = [ { "device.name" = name; } ];
            actions.update-props."device.profile" = "off";
          }) cfg.parkedCards;
        };
      })

      (lib.mkIf cfg.bluetooth.enable {
        # Battery reporting and the A2DP/HFP endpoints BlueZ hands to PipeWire.
        hardware.bluetooth.settings.General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };

        services.pipewire.wireplumber.extraConfig = {
          "50-bluez-codecs"."monitor.bluez.properties" = {
            "bluez5.codecs" = cfg.bluetooth.codecs;
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
          };

          "51-bluez-policy"."wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = cfg.bluetooth.autoswitchToHeadsetProfile;
            "bluetooth.profile-preference" = "quality";
          };
        };
      })
    ]
  );
}
