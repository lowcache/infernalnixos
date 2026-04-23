{ config, lib, pkgs, modulesPath, ... }: {
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  }; [cite: 129, 151, 163]

  fileSystems."/boot" = { device = "/dev/disk/by-label/BOOT"; fsType = "vfat"; };
  fileSystems."/nix" = { device = "/dev/disk/by-label/NIX"; fsType = "ext4"; };
  fileSystems."/persist" = { 
    device = "/dev/disk/by-label/PERSIST"; 
    fsType = "ext4"; 
    neededForBoot = true; 
  }; [cite: 130, 213]

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/networkmanager"
      "/etc/secureboot"
    ];
    files = [ "/etc/machine-id" ];
  };
}
