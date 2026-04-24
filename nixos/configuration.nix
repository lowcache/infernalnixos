{ config, pkgs, inputs, ... }: {
  # Kernel & Performance
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  services.scx.enable = true; # Enables BORE scheduler via CachyOS kernel [cite: 77, 102]
  
  # Asus Hardware Support
  imports = [ inputs.nixos-hardware.nixosModules.asus-zephyrus-ga401 ]; # Adjust model as needed [cite: 118]
  services.asusd.enable = true;
  services.supergfxd.enable = true;
  services.power-profiles-daemon.enable = true;

  # Security & Anonymity
  networking.networkmanager.enable = true;
# dependency build error cascade kills build (dependency:rust) 
#  boot.lanzaboote = {
#    enable = true;
#    pkiBundle = "/etc/secureboot";
#  };
  # BootLoader - will be unnecessary when secureboot/lanzaboote is fixed
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.networkmanager.wifi.scanRandMacAddress = true;
  
  # Android & Connectivity
  users.users.nondeus = {
  	isNormalUser = true;
  	hashedPassword = "$6$TC4VPrCqV64Jitm3$2yZL1T8LhyMHM7rU7wLcKxQqhtdhhWrsRSPIOaJ7t4u2ML8pI53kBSpe/KYWx8B7xrEfLMGsKX5xp8.Oo1qTo.";
  	extraGroups = [ "adbusers" "networkmanager" "wheel" "video" ];
  };
  programs.kdeconnect.enable = true;
  
  # Application Support
  services.flatpak.enable = true;
  xdg.portal = {
  	enable = true;
  	extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  	config.common.default = "*";
  };
  # Snap support is typically handled via appimage or flatpak in pure NixOS
  
  environment.systemPackages = with pkgs; [
    sbctl
    wireguard-tools
    tor
    git
    fish
    android-studio
    android-tools
  ];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.11";
}
