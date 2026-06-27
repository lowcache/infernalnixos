{ config, pkgs, lib, ... }:
{
  # Global agent tooling on PATH for every project, not just this repo.
  # Out-of-store symlinks (same rationale as dots/: live-editable without a
  # rebuild). memd and tether each graduated to their own repos under
  # ~/CodeRepo (decision #18 for memd): a single live copy runs everywhere, so
  # there is no store/live drift to reconcile. python3 for the shebang comes from
  # the user profile already on the service PATH below.
  home.file = {
    ".local/bin/memd" = {
      source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/CodeRepo/memd/memd.py";
      force = true;
    };
    ".local/bin/tether" = {
      source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/CodeRepo/tether/bin/tether";
      force = true;
    };
    ".local/bin/agent-scaffold" = {
      source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/scripts/agent-scaffold/agent-scaffold";
      force = true;
    };
  };

  # Periodic sweep: catches sessions the hooks missed (antigravity, crashes,
  # other CLIs via .memory/inbox/), prunes oversized files, auto-detects and
  # scaffolds new projects. Hooks handle the hot path at session boundaries.
  systemd.user.services.memd-sweep = {
    Unit.Description = "memd project-memory sweep";
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/memd sweep";
      # memd + claude live in ~/.local/bin; python3 (shebang) + git from the
      # user/system profiles.
      Environment = "PATH=${config.home.homeDirectory}/.local/bin:/run/current-system/sw/bin:/etc/profiles/per-user/${config.home.username}/bin";
      Nice = 10;
    };
  };

  systemd.user.timers.memd-sweep = {
    Unit.Description = "Periodic memd project-memory sweep";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "30min";
      RandomizedDelaySec = "2min";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
