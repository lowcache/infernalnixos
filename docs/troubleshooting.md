# Troubleshooting & Known Workarounds

Active mitigations baked into the configuration, and notes on hardware-specific quirks.

## Krita canvas freeze (Qt6 / Wayland on Hyprland)

*Note: Hyprland is no longer the desktop (replaced by niri); this entry is kept as a historical record of the mitigation.*

Krita 6 (Qt6) native Wayland crashes/freezes on document or canvas switching under Hyprland with a
hybrid GPU. **Historical Mitigation:** Krita was repackaged in
[`home/pkgs.nix`](https://github.com/lowcache/volnixos/blob/main/home/pkgs.nix) with `symlinkJoin` +
`makeWrapper` to force XWayland:

```nix
krita-wrapped = pkgs.symlinkJoin {
  name = "krita";
  paths = [ pkgs.krita ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/krita --set QT_QPA_PLATFORM xcb
  '';
};
```

## xdg-desktop-portal access errors

Symptom (file dialogs / file-roller failing):

```
GDBus.Error:org.freedesktop.DBus.Error.AccessDenied:
Portal operation not allowed: Unable to open /proc/[pid]/root
```

*Note: This originated under Hyprland, which is no longer the primary desktop, but is preserved for historical context.*

Per the note in
[`nixos/configuration.nix`](https://github.com/lowcache/volnixos/blob/main/nixos/configuration.nix),
the root cause was Hyprland's `cap_sys_nice` wrapper leaking ambient `CAP_SYS_NICE` to clients, so the
capless portal failed the kernel's `cap_ptrace_access_check` when opening `/proc/<pid>/root`. This was
fixed upstream in **Hyprland 0.55.3**, and the session bus uses the default `dbus-broker` again.

!!! tip "Temporary fallback"
    If a portal regression resurfaces, launch the affected app with capabilities stripped:
    ```bash
    setpriv --ambient-caps -all --inh-caps -all <app>
    ```

## dGPU battery drain

The NVIDIA dGPU should reach RTD3 (0 W) suspend when idle. The Ollama daemon sets
`OLLAMA_KEEP_ALIVE=5m` so it unloads models and releases CUDA handles, allowing the card to power down.
Confirm idle power with `nvtop` / `cat /sys/bus/pci/devices/<dGPU>/power_state`.

## Slow shutdown / stuck units

`systemd.settings.Manager.DefaultTimeoutStopSec = "10s"` (5s for the user manager) caps unit stop
time, and the `decapitate-fuse-mounts` oneshot force-unmounts the xdg-document-portal FUSE at shutdown
to release `/nix`. MicroVM units carry their own `TimeoutStopSec` overrides for fast teardown.

## Secure Boot won't boot

If the machine fails to boot after enabling enforcing Secure Boot, confirm the generation is signed
**before** rebooting (`sbctl verify`) and that keys are enrolled (`sbctl status`). See
[Boot & Secure Boot](architecture/boot.md).
