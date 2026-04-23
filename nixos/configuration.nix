{ config, pkgs, inputs, ... }: {
  # Kernel & Performance
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  services.scx.enable = true; # Enables BORE scheduler via CachyOS kernel [cite: 77, 102]
  
  # Asus Hardware Support
  imports = [ inputs.nixos-hardware.nixosModules.asus-zephyrus-ga401 ]; # Adjust model as needed [cite: 118]
  services.asusd.enable = true;
  services.supergfxd.enable = true;
  services.power-profiles-daemon.enable = true; [cite: 104]

  # Security & Anonymity
  networking.networkmanager.enable = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  }; [cite: 107]
  networking.networkmanager.wifi.scan-rand-mac-address = true; [cite: 108]
  
  # Android & Connectivity
  programs.adb.enable = true;
  users.users.nondeus.extraGroups = [ "adbusers" "networkmanager" "wheel" "video" ]; [cite: 249]
  programs.kdeconnect.enable = true; [cite: 232, 250]
  
  # Application Support
  services.flatpak.enable = true;
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

  system.stateVersion = "24.11";
}
