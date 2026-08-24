# Anonymous-mode isolation: UID-marked egress policy-routed through the
# net-gate Tor VM. Consolidates what used to be four distant sections of the
# old monolithic configuration.nix (firewall mangle rules, anon-routing,
# anon-socks-check, targets.anonymous, users.anon-user).
#
# Arm/disarm (manual/on-demand, never autostarts):
#   arm:    sudo systemctl start anonymous.target
#   disarm: sudo systemctl stop  anonymous.target
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vol.anon-mode;
in
{
  options.vol.anon-mode = {
    enable = lib.mkEnableOption "anonymous-mode egress via the net-gate Tor VM";

    uid = lib.mkOption {
      type = lib.types.int;
      default = 10000;
      description = ''
        Anonymous-mode isolation UID. Processes launched as this user (via
        `anon-run`) have their egress marked and policy-routed through the
        net-gate Tor VM. Fixed so the firewall owner-match is stable.
      '';
    };

    torVmAddress = lib.mkOption {
      type = lib.types.str;
      default = "192.168.100.2";
      description = "net-gate guest address (Tor SOCKS5 :9050).";
    };

    fwmark = lib.mkOption {
      type = lib.types.str;
      default = "0x1";
    };

    routingTable = lib.mkOption {
      type = lib.types.int;
      default = 100;
    };
  };

  config = lib.mkIf cfg.enable {
    # Anonymous-mode egress marking. Deliberately NOT networking.nftables.enable:
    # that disables the ip_tables module and breaks Docker + libvirt networking
    # on this host (nixpkgs #24318). Instead we add a mangle OUTPUT rule via the
    # existing iptables backend that marks packets owned by anon-user; the
    # anon-routing service policy-routes the fwmark to the Tor VM. Only
    # marked-UID traffic is touched, so normal user/system traffic is unaffected.
    networking.firewall.extraCommands = ''
      iptables -t mangle -A OUTPUT -m owner --uid-owner ${toString cfg.uid} -j MARK --set-mark ${cfg.fwmark}
    '';
    networking.firewall.extraStopCommands = ''
      iptables -t mangle -D OUTPUT -m owner --uid-owner ${toString cfg.uid} -j MARK --set-mark ${cfg.fwmark} 2>/dev/null || true
    '';

    users.users.anon-user = {
      inherit (cfg) uid;
      isSystemUser = true;
      group = "nogroup";
      description = "UID for anonymous-mode app isolation";
    };

    # Policy routing for anonymous mode: fwmark -> table -> default via the
    # net-gate Tor VM. On-demand only (no wantedBy): pulled up by
    # anonymous.target, so it never races the VM tap at boot. The table is
    # non-default — only marked packets use it, so normal traffic is untouched.
    #
    # Readiness gate (anon-socks-check): block until the VM's Tor SOCKS5 is
    # actually reachable (VM unit being 'active' != Tor bootstrapped), then
    # report status. Proxy-only — deliberately no DNS override (too disruptive).
    systemd.services = {
      anon-routing = {
        description = "Policy routing for anonymous-mode egress (UID ${toString cfg.uid} -> Tor VM)";
        after = [
          "network-online.target"
          "microvm@net-gate.service"
        ];
        wants = [ "network-online.target" ];
        partOf = [ "anonymous.target" ]; # torn down when anon mode is stopped
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "anon-routing-up" ''
            ${pkgs.iproute2}/bin/ip rule list | grep -q "fwmark ${cfg.fwmark} lookup ${toString cfg.routingTable}" || \
              ${pkgs.iproute2}/bin/ip rule add fwmark ${cfg.fwmark} table ${toString cfg.routingTable}
            ${pkgs.iproute2}/bin/ip route replace default via ${cfg.torVmAddress} table ${toString cfg.routingTable}
          '';
          ExecStop = pkgs.writeShellScript "anon-routing-down" ''
            ${pkgs.iproute2}/bin/ip route flush table ${toString cfg.routingTable} 2>/dev/null || true
            ${pkgs.iproute2}/bin/ip rule del fwmark ${cfg.fwmark} table ${toString cfg.routingTable} 2>/dev/null || true
          '';
        };
      };

      anon-socks-check = {
        description = "Wait for net-gate Tor SOCKS5 reachability (anonymous mode)";
        after = [ "microvm@net-gate.service" ];
        partOf = [ "anonymous.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "anon-socks-wait" ''
            for i in $(${pkgs.coreutils}/bin/seq 1 30); do
              if ${pkgs.coreutils}/bin/timeout 2 ${pkgs.bash}/bin/bash \
                  -c ": >/dev/tcp/${cfg.torVmAddress}/9050" 2>/dev/null; then
                echo "Tor SOCKS5 reachable at ${cfg.torVmAddress}:9050 — anonymous mode armed."
                exit 0
              fi
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "Timed out waiting for Tor SOCKS5 at ${cfg.torVmAddress}:9050" >&2
            exit 1
          '';
        };
      };
    };

    # One-shot arm/disarm for anonymous mode. Manual/on-demand: no wantedBy, so
    # it never autostarts at boot. Pulls up the net-gate VM (if down), the egress
    # policy routing, and the SOCKS readiness check. Stopping it tears down the
    # partOf units (routing + check) but leaves the net-gate VM running, since the
    # VM is only `wants` here — it's still useful without anon mode.
    systemd.targets.anonymous = {
      description = "Anonymous mode: egress via the net-gate Tor VM (manual/on-demand)";
      wants = [
        "microvm@net-gate.service"
        "anon-routing.service"
        "anon-socks-check.service"
      ];
      after = [ "microvm@net-gate.service" ];
    };
  };
}
