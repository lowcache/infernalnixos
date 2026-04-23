# NixOS Migration: CachyNixOS to Pure NixOS

This repository serves as the single source of truth for a pure NixOS (Unstable) environment on an Asus notebook. It implements the **"Erase Your Darlings"** protocol while utilizing a **Wrapper Strategy** to preserve engineered UI components—including the Python-bridged QML logic—exactly as they exist in the original `lowcache/CachyNixOS` repository.

## 1. Repository Structure
The repository is organized to maintain strict version control and ease of dissemination:

* `flake.nix`: The central orchestrator pulling in CachyOS performance layers and security modules.
* `home.nix`: The UI Integrator managing custom UI symlinks and application persistence.
* `README.md`: This file (migration instructions).
* `nixos/configuration.nix`: System-level settings for performance, security, and Android tools.
* `nixos/hardware-configuration.nix`: Forensic neutralization via root-on-tmpfs.

## 2. Migration Instructions

### I. Partitioning & Layout
1.  **Label Disks**: Ensure your partitions are correctly labeled as `BOOT` (vfat), `NIX` (ext4), and `PERSIST` (ext4).
2.  **Mounting (Impermanence)**:
    * Mount root (`/`) on `tmpfs` to eliminate forensic residue upon reboot.
    * Mount `/nix` to the `NIX` partition.
    * Mount `/persist` to the `PERSIST` partition.

### II. Repository Synchronization
1.  **Placement**: Clone both the `CachyNixOS` repository and this migration repository into `/persist/home/nondeus/.nix-config/`.
2.  **Validation**: Before rebooting, verify that `quickshell/modules/advanced settings` and appearance scripts are present in that directory to ensure the Pythonic bridge remains active.

### III. Post-Install Security Handshake
1.  **Secure Boot**: Use `sbctl` to enroll keys into UEFI to transition Lanzaboote from "Audit" to "Deployed" mode.
2.  **ZAP CA**: Launch the Brave browser and import the ZAP Root CA from `~/.ZAP`. 
    * **Note**: Ensure Brave is included in the persistence block to avoid repeating this on every reboot.
3.  **Forensic Scrubbing**: Verify that `~/.ZAP/logs/` is **not** included in persistence to ensure execution metadata is wiped from memory on reboot.

### IV. Android & Phone Connectivity
1.  **ADB/Fastboot**: Plug in your device and authorize the host; the `adbusers` group membership is handled declaratively.
2.  **Galaxy S26 Ultra**: Launch KDE Connect on both the laptop and phone to establish an encrypted bridge over the authorized network.

## V. Partitioning & Layout Logic
The migration utilizes a three-tier storage strategy to isolate the system state from user data:
* **Ephemeral Root (`/`)**: A 4GB `tmpfs` (RAM) partition that wipes all non-persistent data on reboot.
* **Store Layer (`/nix`)**: Dedicated `ext4` partition on the primary drive. **Note**: If migrating from a backup-drive `/nix`, data must be rsync'd to the new `NIX` labeled partition to maintain performance.
* **Persistence Layer (`/persist`)**: Primary storage for credentials, browser profiles, and the `Wrapper Strategy` source files.

## VI. Critical Build Pre-Requisites
To prevent `nixos-rebuild` failures, verify these local states:

1. **Wrapper Targets**: Ensure your UI configurations are moved from the old system to:
   `/persist/home/nondeus/.nix-config/`
   The `home.nix` file creates out-of-store symlinks to these exact paths.

2. **Secure Boot (Lanzaboote)**: 
   * Ensure `sbctl` is installed (included in `systemPackages`).
   * The directory `/etc/secureboot` must be present in the persistence block for keys to survive the first reboot.

3. **User Groups**: 
   * Membership for `adbusers` is handled declaratively for Galaxy S26 Ultra connectivity. 
   * Ensure the `nondeus` user is manually added to the `wheel` group if performing the initial install via a live USB.

## VII. Troubleshooting (Offline/No-Tool Environment)
If the build fails or the UI does not initialize:

* **Mount Verification**: Run `findmnt` to ensure `/` is `tmpfs` and `/persist` is mounted with `neededForBoot = true`.
* **Fish Shell Init**: If the shell fails to load, check the `interactiveShellInit` in `home.nix` for syntax errors carried over from CachyOS.
* **Matugen Failures**: The Matugen systemd service is a `oneshot`. If it fails, check that `/path/to/wallpaper` in `home.nix` has been updated to a valid file path in `/persist`.
* **ADB Authorization**: If the S26 Ultra is not detected, check `dmesg` for USB filter conflicts; `services.asusd` and `supergfxd` are active and may affect power delivery to por## VIII. CachyOS Decommissioning & Cleanup
After successfully booting into the Pure NixOS environment, the original CachyOS partitions will still exist on your drive but will not be mounted.

## VIII. CachyOS Decommissioning & Cleanup
After successfully booting into the Pure NixOS environment, the original CachyOS partitions will still exist on your drive but will not be mounted.

1. **Verification**: Confirm that all UI components (Quickshell, Hyprland) are loading correctly from `/persist`.
2. **Deletion**: Once you are confident in the NixOS stability, you can use `parted` or `gparted` to delete the old CachyOS partitions.
3. **Expansion**: You may then expand the `NIX` or `PERSIST` partitions to reclaim the freed space. 
   * **Note**: Because root is on `tmpfs`, expanding partitions does not require unmounting the root filesystem.
4. **Bootloader Cleanup**: Use `sbctl` to verify that only the NixOS/Lanzaboote EFI entries are active in the UEFI firmware.

