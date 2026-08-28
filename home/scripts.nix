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

  # opencode is tether's second worker backend (`tether run -m free|free-big|
  # free-fast`), driving OpenRouter's free tier so bulk work costs no Gemini
  # quota. Declarative because ~/.config is on the tmpfs root: hand-written here
  # it would be gone at the next boot and every free tier would fail closed.
  #
  # small_model matters as much as model. opencode calls a second, cheap model to
  # title sessions, and it defaults to a PAID one -- on this account that returned
  # "requires more credits, or fewer max_tokens" on every run. Pinning it to a
  # free model is what makes an otherwise-free delegation actually free.
  #
  # Both point at OpenCode Zen (opencode/*) rather than OpenRouter: Zen needs no
  # API key and no account, so a bare `opencode` works even where the sops secret
  # is not readable, and it proved the more reliable gateway. The same NVIDIA
  # model returns an empty body through OpenRouter and answers through Zen.
  #
  # The per-tier model chains live in tether itself, not here; this only sets
  # what a bare `opencode` does interactively.
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "opencode/mimo-v2.5-free";
    small_model = "opencode/muse-spark-1.2-contributor-free";
    autoupdate = false; # the store owns the binary; self-update would fight it
    share = "disabled";
  };
}
