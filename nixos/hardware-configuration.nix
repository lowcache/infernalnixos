{ config, lib, pkgs, modulesPath, ... }: {
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };

  fileSystems."/boot" = { device = "/dev/disk/by-label/BOOT"; fsType = "vfat"; };
  fileSystems."/nix" = { device = "/dev/disk/by-label/NIX"; fsType = "ext4"; };
  fileSystems."/persist" = { 
    device = "/dev/disk/by-label/PERSIST"; 
    fsType = "ext4"; 
    neededForBoot = true; 
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/networkmanager"
      "/etc/secureboot"
    ];
    files = [ 
      "/etc/machine-id"
    ];
  };
}
