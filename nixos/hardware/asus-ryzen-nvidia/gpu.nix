{ config, pkgs, ... }: {

  hardware = {
    amdgpu.opencl.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    nvidia-container-toolkit.enable = true;
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      #dynamicboost.enable = true;
      powerManagement = {
        enable = true;
        finegrained = true;
      };
      open = true;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        sync.enable = false;
        reverseSync.enable = false;
        amdgpuBusId = "PCI:102:0:0"; # 66:00.0 hex -> 102 decimal
        nvidiaBusId = "PCI:1:0:0"; # 01:00.0 hex -> 1 decimal
      };
    };
  };

  services.xserver.videoDrivers = [
    "nvidia"
    "amdgpu"
  ];
}
