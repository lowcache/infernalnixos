# Small service toggles with no cross-module coupling. The heavier services
# (Ollama, Open WebUI) live in ai-stack.nix; the graphical session in
# desktop.nix.
{
  services = {
    # Vial keyboard configurator: unprivileged hidraw access for Vial-enabled
    # keyboards (matched by the vial:f64c2b3c magic in the USB serial).
    udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
    upower.enable = true;
    timesyncd.enable = true;
    geoclue2.enable = true;
    scx = {
      enable = false;
      scheduler = "scx_bpfland";
    };
    flatpak.enable = true;
    # dbus-broker (the uwsm default) is in use. A historical 2026-06-10 portal
    # failure on this host traced to the old Hyprland session's cap_sys_nice
    # wrapper leaking ambient CAP_SYS_NICE (not a dbus/pidfd issue) — moot now
    # that Hyprland is gone. See .memory/inbox/2026-06-12-portal-bug-real-root-cause.md.
    asusd.enable = true;
    supergfxd.enable = false;
    power-profiles-daemon.enable = false;
    logind.settings = {
      Login = {
        KillUserProcesses = true;
      };
    };
    #    resolved = {
    #      enable = true;
    #      dnsovertls = "opportunistic";
    #      fallbackDns = [ "1.1.1.1#cloudflare.dns.com" "9.9.9.9#dns.quad9.net" ];
    #    };
  };
}
