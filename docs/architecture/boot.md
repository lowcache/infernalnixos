# Boot & Secure Boot

The boot path uses **Lanzaboote** for native UEFI Secure Boot, replacing the default `systemd-boot`
loader. Configuration lives in [`nixos/configuration.nix`](https://github.com/lowcache/volnixos/blob/main/nixos/configuration.nix).

## Lanzaboote

```nix
boot.loader.systemd-boot.enable = lib.mkForce false;
boot.loader.efi.canTouchEfiVariables = true;
boot.lanzaboote = {
  enable = true;
  pkiBundle = "/etc/secureboot";
};
```

- `systemd-boot` is force-disabled (`lib.mkForce false`) so Lanzaboote owns the EFI entries; the two
  loaders are mutually exclusive.
- Signing keys live in the PKI bundle at `/etc/secureboot`, generated and enrolled with `sbctl`
  (shipped in `environment.systemPackages`).

!!! info "initrd"
    `boot.initrd.systemd.enable = true` — the initrd runs a systemd instance, which is required for a
    clean Lanzaboote + impermanence boot.

## Enrolling keys

Secure Boot must be in **Setup Mode** to enroll new keys. The general flow with `sbctl`:

```bash
sbctl status                 # check Secure Boot / setup mode
sbctl create-keys            # generate the PKI bundle
sudo sbctl enroll-keys -m    # enroll (with Microsoft keys for firmware compatibility)
make switch                  # Lanzaboote signs the generation
sbctl verify                 # confirm signed files
```

!!! warning
    Enrolling keys and toggling Secure Boot are firmware-level operations. Verify `sbctl status`
    shows signed images **before** rebooting into enforcing mode, or the machine may fail to boot.

## Kernel

The bootloader loads the CachyOS kernel; see [Kernel & Performance](kernel.md).
