# 💿 Limbo — Portable Generic Profile

`limbo` is a generic, hardware-independent NixOS profile that builds cleanly on standard `x86_64`
hardware (physical or virtual). It is decoupled from every machine-specific feature of `volnix`. Its
files live under
[`nixos/limbo/`](https://github.com/lowcache/volnixos/tree/main/nixos/limbo)
(`configuration.nix`, `hardware-configuration.nix`); the user is `inlimbo`.

## volnix vs limbo

| `volnix`                              | `limbo`                              |
| :------------------------------------ | :----------------------------------- |
| Lanzaboote UEFI Secure Boot           | standard `systemd-boot`              |
| Impermanence (`tmpfs` root)           | conventional persistent filesystem   |
| `sops-nix` secrets                    | declarative `initialPassword`        |
| Hybrid AMD/NVIDIA + CachyOS kernel    | generic CPU + open display drivers   |
| ASUS / hybrid-GPU services            | omitted                              |

It keeps the shared essentials: Hyprland desktop, `nix-ld`, Docker, Fish, and CPU-friendly Ollama /
Open WebUI.

## Install walkthrough

!!! note "Partition labels matter"
    The configuration mounts by label. Create exactly these:

    | Mount   | Filesystem    | Label   |
    | :------ | :------------ | :------ |
    | `/boot` | `vfat` (FAT32)| `boot`  |
    | `/`     | `ext4`        | `nixos` |

```bash
# 1. Boot a NixOS live ISO, partition + label as above, then mount:
mount -t ext4 /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount -t vfat /dev/disk/by-label/boot /mnt/boot

# 2. Clone the configuration and install the limbo profile
git clone https://github.com/lowcache/volnixos.git /mnt/home/inlimbo/.nix-config
nixos-install --flake /mnt/home/inlimbo/.nix-config#limbo
```

Initial credentials are `root` / `nixos`.

!!! warning "Change passwords on first login"
    `limbo` ships declarative `initialPassword` values for scratch use. Run `passwd` immediately after
    first login, and migrate to `hashedPasswordFile`/sops if the host becomes long-lived.

## Rebuilding

```bash
sudo nixos-rebuild switch --flake ~/.nix-config#limbo
# or, from the repo:
make switch HOST=limbo
```
