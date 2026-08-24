# systemd manager tuning, tmpfiles scaffolding on the tmpfs root, and the
# nix-daemon build-temp relocation.
{
  pkgs,
  username,
  ...
}:
{
  systemd = {
    oomd.enable = false;
    tmpfiles.rules = [
      "d /home/${username} 0700 ${username} users"
      "d /home/${username}/AppImage 0755 ${username} users"
      "d /home/${username}/Storage/ai-generation 0755 ${username} users"
      "d /home/${username}/Storage/ai-generation/fooocus 0755 ${username} users"
      "d /home/${username}/Storage/ai-generation/forge 0755 ${username} users"
      "d /persist/var/lib/tailscale-vm 0700 root root"
      # Disk-backed build temp so nix builds never exhaust the 4G tmpfs root.
      "d /nix/tmp 1777 root root -"
    ];
    services = {
      #greetd.serviceConfig = {
      #StandardInput = "tty";
      #StandardOutput = "tty";
      #StandardError = "journal";
      #TTYReset = true;
      #TTYHangup = true;
      #TTYDeallocate = true;
      #};
      nix-daemon.serviceConfig.KillMode = "process";
      # Build temp on /nix (root-owned, nixbld-accessible) — never the RAM tmpfs.
      # Must NOT live under /home/lowcache (0700) or nixbld can't traverse it.
      nix-daemon.environment.TMPDIR = "/nix/tmp";
      decapitate-fuse-mounts = {
        description = "Force lazy unmount of xdg-document-portal FUSE to release /nix";
        before = [ "local-fs.target" ];
        wantedBy = [
          "shutdown.target"
          "reboot.target"
          "halt.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          DefaultDependencies = false;
          ExecStart = "${pkgs.coreutils}/bin/umount -f -l /run/user/1000/doc || true";
          ExecStopPost = "${pkgs.psmisc}/bin/killall -9 xdg-document-portal fusermount3";
        };
      };
    };
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
      DefaultRestartSec = "1s";
    };
    user.settings.Manager.DefaultTimeoutStopSec = "5s";
  };
}
