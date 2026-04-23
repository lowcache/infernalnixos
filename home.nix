{ config, pkgs, lib, ... }: {
  home.username = "ghost";
  home.homeDirectory = "/home/ghost";

  # Wrapper Strategy: Preserving Pythonic QML Bridges [cite: 85, 113, 198]
  home.file.".config/quickshell".source = config.lib.file.mkOutOfStoreSymlink "/persist/home/ghost/.nix-config/quickshell";
  home.file.".config/hypr".source = config.lib.file.mkOutOfStoreSymlink "/persist/home/ghost/.nix-config/hypr";
  home.file.".config/ii".source = config.lib.file.mkOutOfStoreSymlink "/persist/home/ghost/.nix-config/illogical-impulse";

  # Applications & Workflows
  home.packages = with pkgs; [
    kitty
    brave
    vscodium
    gedit
    krita
    matugen
    # Add AionUi package here once defined
  ]; [cite: 222]

  # Persistence Audit [cite: 90, 131, 229]
  home.persistence."/persist/home/ghost" = {
    directories = [
      ".local/share/fish"
      ".local/share/direnv"
      ".ssh"
      "Documents"
      "Downloads"
      ".config/BraveSoftware"
      ".ZAP" # Persistence for ZAP Config/CA [cite: 91]
      "ZAP-Sessions" # Persistence for ZAP Data [cite: 91]
    ];
    allowOther = true;
  };

  # ZAP Forensic Scrubbing: ~/.ZAP/logs is implicitly wiped from tmpfs [cite: 93, 115, 230]

  programs.fish = {
    enable = true;
    # Incorporate your source interactiveShellInit here
  }; [cite: 177, 188]

  systemd.user.services.matugen = {
    Unit.Description = "Declarative Matugen Color Engine";
    Service = {
      ExecStart = "${pkgs.matugen}/bin/matugen apply -i /path/to/wallpaper";
      Type = "oneshot";
    };
  }; [cite: 94, 120]

  home.stateVersion = "24.11";
}
