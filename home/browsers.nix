{ config, pkgs, lib, ... }: {
  # Brave Browser (Primary)
  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--disable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,WaylandWpColorManagerV1"
      "--disable-gpu-memory-buffer-video-frames"
      "--enable-features=TouchpadOverscrollHistoryNavigation"
      "--enable-gpu-rasterization"
      "--enable-oop-rasterization"
      "--enable-zero-copy"
    ];
  };

  # Floorp Browser (Stable Firefox Fork Backup)
  home.packages = [
    pkgs.floorp-bin
  ];
}
