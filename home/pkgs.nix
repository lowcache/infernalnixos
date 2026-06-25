{ config, pkgs, lib, inputs, ... }: {

  home = {
    packages =
      let
        basedevel = with pkgs; [
          gcc
          automake
          autoconf
          pkg-config
          binutils
          glibc
          gdb
          cmake
          gnumake
          progress
          moreutils
          cpufrequtils
          strace
          ltrace
          gperf
          patch
          diffutils
          findutils
          gawk
          gnugrep
          gnutar
          gzip
          coreutils
          go
          dart-sass
          python3
          glib
          nodejs
          gtk3
          gtk4
          dconf
        ];
        quickshell = with pkgs; [
          inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
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
          kdePackages.dolphin
          bibata-cursors
          bibata-cursors-translucent
        ];
        krita-wrapped = pkgs.symlinkJoin {
          name = "krita";
          paths = [ pkgs.krita ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          # Compositor-aware platform: Qt6-native-Wayland Krita froze on canvas/tab
          # switch under Hyprland + hybrid GPU (decision #4), so force xcb (XWayland)
          # there. niri has no built-in XWayland and native Wayland Krita works fine
          # (better stylus/tablet support too), so use wayland under niri.
          postBuild = ''
            wrapProgram $out/bin/krita \
              --run 'if [ -n "$NIRI_SOCKET" ]; then export QT_QPA_PLATFORM=wayland; else export QT_QPA_PLATFORM=xcb; fi'
          '';
        };
        hyprland-niri = with pkgs; [
          # hyprland utils
          hypridle
          hyprlock
          hyprcursor
          hyprland-qt-support
          hyprpaper
          hyprpicker
          # niri-utils
          nirius
          nirimon
          pamixer
          pavucontrol
          xwayland
          xwayland-satellite
          awww
          waypaper
          thunderbird
          adw-gtk3
          cliphist
          libnotify
          fuzzel
          kitty
          krita-plugin-gmic
          krita-wrapped
          gimp-with-plugins
          imagemagick
          papirus-icon-theme
          gsettings-desktop-schemas
          vscodium
          gedit
          file-roller
          cava
          swappy
          wl-clipboard
          grim
          slurp
          matugen
          networkmanagerapplet
          spotify
          floorp-bin # Firefox-fork backup browser
        ];
        typography = with pkgs; [
          material-symbols
          nerd-fonts.symbols-only
          nerd-fonts.jetbrains-mono
          nerd-fonts.ubuntu-sans
          nerd-fonts.sauce-code-pro
          nerd-fonts.intone-mono
          nerd-fonts.martian-mono
          nerd-fonts.roboto-mono
          nerd-fonts.anonymice
          nerd-fonts.hack
          nerd-fonts.hurmit
          nerd-fonts.hasklug
          nerd-fonts.geist-mono
          nerd-fonts.commit-mono
          nerd-fonts.code-new-roman
          nerd-fonts.blex-mono
          nerd-fonts.envy-code-r
          nerd-fonts.victor-mono
          nerd-fonts.recursive-mono
          nerd-fonts.departure-mono
          nerd-fonts.zed-mono
          nerd-fonts.atkynson-mono
        ];
        terminal = with pkgs; [
          fish
          git
          gh
          gh-s
          ghdorker
          ghfetch
          ghgrab
          fzf
          eza
          tgpt
          hdrop
          bat
          gnupg
          gpg-tui
          sops
          ssh-to-age
          ripgrep
          ripgrep-all
          flatpak
          feh
          fd
          jq
          bc
          tor
          micro
          cryptsetup
          htop
          bat-extras.batgrep
          psmisc
          direnv
          playerctl
          brightnessctl
          socat
          gawk
          acpi
          tree
          upower
          ddcutil
          clinfo
          git-lfs
          nil
          android-tools
          nixpkgs-fmt
          inputs.volinit.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
        nixified-ai = with pkgs; [
          mcp-nixos
          mcp-gateway
          github-mcp-server
          markitdown-mcp
          playwright-mcp
          context7-mcp
          mcp-server-sequential-thinking
          open-websearch
          icm
          mcp-server-fetch
          llmfit
          # mcp-server-filesystem
          claude-code
          claude-code-router
          gemini-cli
          github-copilot-cli
          codex
          rtk
          pkgs.llm-agents.claude-plugins
          pkgs.llm-agents.hermes-agent
          pkgs.llm-agents.hermes-hud
          pkgs.llm-agents.hermes-desktop
          pkgs.llm-agents.catnip
          pkgs.llm-agents.letta-code
        ];
      in
      nixified-ai ++ terminal ++ typography ++ hyprland-niri ++ quickshell ++ basedevel;
  };
}
