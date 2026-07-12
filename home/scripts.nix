{ config, pkgs, ... }:
let
  # Single source of truth for the net-gate Tor VM address. Change here only.
  torVmIp = "192.168.100.2";
  torSocksPort = "9050";
  # Fail fast with a clear message if the Tor VM isn't up. runtimeShell is bash,
  # so /dev/tcp works; timeout bounds the connect so a dead VM can't hang us.
  checkTor = ''
    if ! ${pkgs.coreutils}/bin/timeout 2 ${pkgs.bash}/bin/bash \
        -c ": >/dev/tcp/${torVmIp}/${torSocksPort}" 2>/dev/null; then
      echo "tor: net-gate VM unreachable at ${torVmIp}:${torSocksPort} — arm it with 'sudo systemctl start anonymous.target' (or 'anon-on')." >&2
      exit 1
    fi
  '';
in
{
  # Tor per-app proxy wrappers. All route through the net-gate VM's SOCKS5
  # (P5-T1). Each checks VM reachability first. Referenced packages (brave,
  # curl, sudo) are already in the system/home closure — nothing new installed.
  home.packages = [
    (pkgs.writeShellScriptBin "tor-brave" ''
      ${checkTor}
      exec ${pkgs.brave}/bin/brave \
        --proxy-server="socks5://${torVmIp}:${torSocksPort}" \
        --proxy-bypass-list="<-loopback>" \
        --user-data-dir="$HOME/.config/BraveSoftware/Brave-Browser-Tor" \
        "$@"
    '')
    (pkgs.writeShellScriptBin "tor-curl" ''
      ${checkTor}
      exec ${pkgs.curl}/bin/curl --socks5-hostname ${torVmIp}:${torSocksPort} "$@"
    '')
    (pkgs.writeShellScriptBin "tor-check" ''
      ${checkTor}
      exec ${pkgs.curl}/bin/curl --socks5-hostname ${torVmIp}:${torSocksPort} \
        https://check.torproject.org/api/ip
    '')
    (pkgs.writeShellScriptBin "anon-run" ''
      ${checkTor}
      if [ "$#" -eq 0 ]; then
        echo "Usage: anon-run <command> [args...]" >&2
        exit 1
      fi
      exec /run/wrappers/bin/sudo -u anon-user ${pkgs.coreutils}/bin/env \
        https_proxy=socks5h://${torVmIp}:${torSocksPort} \
        http_proxy=socks5h://${torVmIp}:${torSocksPort} \
        "$@"
    '')
  ];

  # Global agent tooling on PATH for every project, not just this repo.
  # Out-of-store symlinks (same rationale as dots/: live-editable without a
  # rebuild). memd and tether each graduated to their own repos under
  # ~/CodeRepo (decision #18 for memd): a single live copy runs everywhere, so
  # there is no store/live drift to reconcile. python3 for the shebang comes from
  # the user profile already on the service PATH below.
  home.file = {
    ".local/bin/tether" = {
      source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/CodeRepo/tether/bin/tether";
      force = true;
    };
    ".local/bin/agent-scaffold" = {
      source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/scripts/agent-scaffold/agent-scaffold";
      force = true;
    };
  };

}
