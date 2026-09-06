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
    # playwright-mcp's nixpkgs wrapper bakes a read-only PLAYWRIGHT_BROWSERS_PATH,
    # then tries to install chrome-for-testing inside it, so no browser launches.
    # Point --executable-path at the driver's own chrome instead: it is already in
    # playwright-mcp's runtime closure (no added size), it sets SSL_CERT_FILE and
    # FONTCONFIG_FILE, and it execs the exact chromium playwright-mcp was built
    # against. The previous loose script globbed all of /nix/store and picked a
    # stale playwright-chromium by sort order.
    (pkgs.writeShellScriptBin "playwright-mcp-nix" ''
      out="''${PLAYWRIGHT_MCP_OUTPUT:-$HOME/Storage/playwright-mcp}"
      ${pkgs.coreutils}/bin/mkdir -p "$out"
      exec ${pkgs.playwright-mcp}/bin/playwright-mcp \
        --headless --no-sandbox --isolated \
        --output-dir "$out" \
        --executable-path ${pkgs.playwright-driver.browsers}/chromium-*/chrome-linux64/chrome \
        "$@"
    '')
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

    # lidkeep — close the lid without suspending, for a bounded window.
    #
    # The problem: HandleLidSwitch is unset everywhere in this repo and in the
    # effective logind config, so it sits on systemd's default of `suspend`.
    # Closing the lid freezes every process. They resume intact — suspend is not
    # a kill — but nothing PROGRESSES while the lid is shut, and anything
    # mid-flight over the network is usually dead by the time it comes back.
    # That is the wrong behaviour when the machine has to be physically carried
    # somewhere while a long job runs.
    #
    # WHY TIMED, AND NOT A PLAIN ON/OFF FLIP. A laptop that never suspends on
    # lid close is a laptop that runs at load inside a closed bag with no
    # airflow. A permanent toggle is one forgotten command away from a thermal
    # problem, so the hold always carries a deadline and releases itself.
    #
    # WHY AN INHIBITOR RATHER THAN services.logind.lidSwitch = "ignore". The
    # declarative option is a system-wide permanent change needing a rebuild to
    # set and another to undo, which is the opposite of a toggle. A logind
    # inhibitor is the mechanism desktops already use for this — niri holds one
    # on handle-power-key on this very machine — it needs no privilege, and it
    # cannot outlive the process holding it.
    #
    # WHY systemd-run RATHER THAN A BARE BACKGROUND PROCESS. systemd owns the
    # lifetime, the unit name is stable so `stop` always finds it, and the lock
    # dies with the unit even if the shell that started it is gone.
    #
    # Note when debugging: the inhibitor takes about a second to appear in
    # `systemd-inhibit --list`. Checking for it immediately after systemd-run
    # returns reports a false absence — that race is not a broken mechanism.
    (pkgs.writeShellScriptBin "lidkeep" ''
      set -euo pipefail
      SYSTEMCTL=${pkgs.systemd}/bin/systemctl
      RUN=${pkgs.systemd}/bin/systemd-run
      INHIBIT=${pkgs.systemd}/bin/systemd-inhibit
      DATE=${pkgs.coreutils}/bin/date
      SLEEP=${pkgs.coreutils}/bin/sleep
      UNIT=lidkeep

      held() { [ "$($SYSTEMCTL --user is-active $UNIT 2>/dev/null)" = active ]; }

      case "''${1-}" in
        stop)
          if held; then
            $SYSTEMCTL --user stop $UNIT
            echo "lidkeep: released. Closing the lid suspends again."
          else
            echo "lidkeep: not held; nothing to release."
          fi
          exit 0
          ;;
        status)
          if held; then
            echo "lidkeep: HELD — the lid will not suspend."
            $INHIBIT --list 2>/dev/null | grep lidkeep || true
          else
            echo "lidkeep: not held. Closing the lid suspends."
          fi
          exit 0
          ;;
        -h|--help)
          echo "Usage: lidkeep [DURATION]   hold lid-open behaviour (default 30m)"
          echo "       lidkeep stop         release now"
          echo "       lidkeep status       show whether it is held"
          echo "DURATION: 90s, 45m, 2h, or a bare number meaning minutes."
          exit 0
          ;;
      esac

      DUR="''${1-30m}"
      case "$DUR" in
        *s) SEC=''${DUR%s} ;;
        *m) SEC=$(( ''${DUR%m} * 60 )) ;;
        *h) SEC=$(( ''${DUR%h} * 3600 )) ;;
        *[!0-9]*)
          echo "lidkeep: bad duration: $DUR" >&2
          echo "  use 90s, 45m, 2h, or a plain number meaning minutes." >&2
          exit 1
          ;;
        *) SEC=$(( DUR * 60 )) ;;
      esac
      if [ "$SEC" -le 0 ]; then
        echo "lidkeep: duration must be positive." >&2
        exit 1
      fi

      UNTIL=$($DATE -d "@$(( $($DATE +%s) + SEC ))" "+%H:%M")

      # Re-arming replaces the current window rather than stacking a second unit.
      if held; then $SYSTEMCTL --user stop $UNIT; fi

      # --quiet drops systemd-run's "Running as unit:" banner, which goes to
      # stderr and would otherwise print above our own message. Errors still show.
      $RUN --quiet --user --unit=$UNIT --description="lid-switch inhibited until $UNTIL" \
        $INHIBIT --what=handle-lid-switch --who=lidkeep \
                 --why="held until $UNTIL" --mode=block \
        $SLEEP "$SEC" >/dev/null

      echo "lidkeep: held until $UNTIL. Lid close will NOT suspend until then."
      echo "  The session will also NOT lock — the lock fires on sleep, and"
      echo "  there is no sleep to fire on. Lock by hand if you are carrying it."
      echo "  In a closed bag this runs with no airflow. Release early with:"
      echo "    lidkeep stop"
      if [ "$SEC" -gt 7200 ]; then
        echo "  WARNING: over two hours of no-suspend. Deliberate?" >&2
      fi
    '')
  ];

  # Global agent tooling on PATH for every project, not just this repo.
  # Out-of-store symlinks (same rationale as dots/: live-editable without a
  # rebuild). memd, tether and agent-scaffold each graduated to their own repos
  # under ~/CodeRepo (decision #18 for memd): a single live copy runs
  # everywhere, so there is no store/live drift to reconcile. python3 for the shebang comes from
  # the user profile already on the service PATH below.
  home.file = {
    ".local/bin/tether" = {
      source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/CodeRepo/tether/bin/tether";
      force = true;
    };
    ".local/bin/agent-scaffold" = {
      source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/CodeRepo/agent-scaffold/agent-scaffold";
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
