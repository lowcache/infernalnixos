{ config, pkgs, lib, ... }: 

let
  # We define the entire set of session variables once in this let block.
  sessionVariables =
    let
      qtDependencies = with pkgs; [
        qt6.qtwayland
        qt6.qtsvg
        qt6.qt5compat
        qt6.qtdeclarative
        qt6.qtpositioning
        qt6.qtmultimedia
        qt6.qtquicktimeline
        qt6.qtimageformats
        qt6.qtvirtualkeyboard
        qt6.qtsensors
        qt6.qttools
        qt6.qttranslations
        qt6.qtwebsockets
        qt6.qtshadertools
        qt6.qtscxml
        kdePackages.kirigami.unwrapped
        kdePackages.kirigami-addons
        kdePackages.breeze-icons
        kdePackages.qqc2-desktop-style
        kdePackages.syntax-highlighting
      ];
    in
    {
      QML2_IMPORT_PATH = pkgs.lib.concatMapStringsSep ":" (pkg: "${pkg}/lib/qt-6/qml:${pkg}/lib/qml") qtDependencies + ":${config.home.homeDirectory}/.config/quickshell/ii";
      QML_IMPORT_PATH = pkgs.lib.concatMapStringsSep ":" (pkg: "${pkg}/lib/qt-6/qml:${pkg}/lib/qml") qtDependencies + ":${config.home.homeDirectory}/.config/quickshell/ii";
      QT_PLUGIN_PATH = pkgs.lib.concatMapStringsSep ":" (pkg: "${pkg}/lib/qt-6/plugins:${pkg}/lib/plugins") qtDependencies;
      # wayland/hyprland/quickshell variables
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      GDK_BACKEND = "wayland,x11";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      # Force GTK apps and Chromium to use XDG Desktop Portal for file choosers
      GTK_USE_PORTAL = "1";
      # Wayland support for Electron/Chromium
      NIXOS_OZONE_WL = "1";
      # Keep scratch + caches OFF the 4G tmpfs root: redirect to the roomy ~/Storage
      # volume at the environment level so it holds for every session process (shells,
      # tools, the Claude Code harness) without depending on per-action discipline.
      # XDG_CACHE_HOME is set canonically via xdg.cacheHome in persist.nix (setting it
      # here would conflict with home-manager's xdg module). It is honored by pip,
      # quickshell/ii (applycolor.sh), llmfit, etc.
      TMPDIR = "${config.home.homeDirectory}/Storage/tmp";
      PIP_CACHE_DIR = "${config.home.homeDirectory}/Storage/.cache/pip";
      CLAUDE_CODE_TMPDIR = "${config.home.homeDirectory}/Storage/tmp/claude";
      # nvidia specific (commented out to allow Hyprland session to render on integrated AMD GPU)
      # LIBVA_DRIVER_NAME = "nvidia";
      # GBM_BACKEND = "nvidia-drm";
      # __NV_PRIME_RENDER_OFFLOAD = "1";
      # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # __VK_LAYER_NV_optimus = "NVIDIA_only";
    };

in
{

  imports = [
    ./persist.nix
    ./pkgs.nix
    ./scripts.nix
    ./shell.nix
    ./noctalia.nix
  ];

  home = {
    username = "lowcache";
    homeDirectory = "/home/lowcache";
    stateVersion = "24.11";
    enableNixpkgsReleaseCheck = false;
    sessionVariables = sessionVariables;
    # Ensure the redirected scratch/cache roots exist before anything writes to them.
    activation.ensureScratchDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "$HOME/Storage/tmp/claude" "$HOME/Storage/.cache/pip"
    '';
    pointerCursor = {
      package = pkgs.bibata-cursors-translucent;
      name = "Bibata-Modern-Translucent";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    gtk4 = {
      theme = null;
    };
  };

  systemd = {
    user = {
      sessionVariables = sessionVariables;
    };
  };
  
  xdg.desktopEntries = {
    antigravity = {
      name = "Antigravity";
      comment = "Antigravity Gemini Desktop Application";
      exec = "${config.home.homeDirectory}/.local/bin/antigravity";
      icon = "system-run";
      type = "Application";
      categories = [ "Utility" "Development" ];
      mimeType = [ "x-scheme-handler/Antigravity" ];
    };
    antigravity-ide = {
      name = "Antigravity-IDE";
      comment = "Antigravity Desktop Integrated Development Environment";
      exec = "${config.home.homeDirectory}/.local/bin/antigravity-ide";
      icon = "${config.home.homeDirectory}/.local/share/Antigravity IDE/resources/app/resources/linux/code.png";
      type = "Application";
      categories = [ "Development" "IDE" ];
    };
  };
}
