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
1.  **Placement**: Clone both the `CachyNixOS` repository and this migration repository into `/persist/home/ghost/.nix-config/`.
2.  **Validation**: Before rebooting, verify that `quickshell/modules/advanced settings` and appearance scripts are present in that directory to ensure the Pythonic bridge remains active.

### III. Post-Install Security Handshake
1.  **Secure Boot**: Use `sbctl` to enroll keys into UEFI to transition Lanzaboote from "Audit" to "Deployed" mode.
2.  **ZAP CA**: Launch the Brave browser and import the ZAP Root CA from `~/.ZAP`. 
    * **Note**: Ensure Brave is included in the persistence block to avoid repeating this on every reboot.
3.  **Forensic Scrubbing**: Verify that `~/.ZAP/logs/` is **not** included in persistence to ensure execution metadata is wiped from memory on reboot.

### IV. Android & Phone Connectivity
1.  **ADB/Fastboot**: Plug in your device and authorize the host; the `adbusers` group membership is handled declaratively.
2.  **Galaxy S26 Ultra**: Launch KDE Connect on both the laptop and phone to establish an encrypted bridge over the authorized network.
