{ config, lib, pkgs, modulesPath, inputs, username, ... }: {

  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
    ./hardware/asus-ryzen-nvidia
  ];

  # Hardware (GPU config lives in ./hardware/asus-ryzen-nvidia/gpu.nix)
  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
  };

  # Swap
  swapDevices = lib.singleton {
    device = "/persist/swapfile";
    size = 16 * 1024; # 16GB physical backup
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Use up to 50% of RAM as compressed swap
  };

  # Impermanence
  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=4G" "mode=755" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };
    "/nix" = {
      device = "/dev/disk/by-label/NIX";
      fsType = "ext4";
    };
    "/persist" = {
      device = "/dev/disk/by-label/PERSIST";
      fsType = "ext4";
      neededForBoot = true;
    };
    "/home/${username}/Storage" = {
      device = "/dev/disk/by-uuid/71548923-2081-44c1-b4f1-6826cb7a6ac8";
      fsType = "ext4";
    };
  };
  # Persistence
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/bluetooth"
      "/var/lib/NetworkManager"
      "/var/lib/docker"
      "/var/lib/greetd"
      "/var/log"
      "/var/lib/flatpak"
      "/var/lib/sbctl"
      "/var/lib/microvm"
      "/var/lib/private/open-webui"
      "/etc/secureboot"
      "/etc/asusd"
      "/etc/ssh"
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
