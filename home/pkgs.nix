{ config, pkgs, lib, inputs, ... }: {

  home = {
    packages =
      let
        baseDev = with pkgs; [
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
        # TODO
        # FIXME
        # Krita Wrapper was a fix under Hyprland the switch to Niri has made this redundant (see comment below) GMIC crashes are prevalent more krita research needed
        # POC: QT_QPA_PLATFORM wayland is already set under home-Manager default.nix
        # SOLUTION1: removal of this wrapper place krita: niriDesktop = with pkgs; [ krita ... ];
        # SOLUTION2: keep krita wrapper and remove postBuild = '' wrapProgram $out/bin/krita --set QT_QPA_PLATFORM wayland '';
        krita-wrapped = pkgs.symlinkJoin {
          name = "krita";
          paths = [ pkgs.krita ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          # Krita runs native Wayland under niri (better stylus/tablet support).
          # The former xcb (XWayland) fallback existed only for Hyprland + hybrid-GPU
          # canvas freezes (decision #4); Hyprland is gone, so Wayland is unconditional.
          postBuild = ''
            wrapProgram $out/bin/krita \
              --set QT_QPA_PLATFORM wayland
          '';
        };
        niriDesktop = with pkgs; [
          hyprpicker # wlroots screen color picker (niri Mod+Shift+C)
          # niri utils
          nirius
          nirimon
          pamixer
          pavucontrol
          xwayland
          xwayland-satellite # dependency for X11 apps under niri
          awww # swww wrapper/replacement
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
          hifile
          sfm
          clex
          far2l
        ];
        monoTypography = with pkgs; [
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
        termUi = with pkgs; [
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
          bat-extras.batgrep
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
        nixAi = with pkgs; [
          mcp-nixos
          mcp-gateway
          github-mcp-server
          markitdown-mcp
          playwright-mcp
          context7-mcp
          mcp-server-sequential-thinking
          open-websearch
          mcp-server-fetch
          llmfit
          # mcp-server-filesystem
          rtk
          claude-code
          claude-code-router
          gemini-cli
          github-copilot-cli
          codex
          pkgs.llm-agents.claude-plugins
          pkgs.llm-agents.hermes-agent
          pkgs.llm-agents.hermes-hud
          pkgs.llm-agents.hermes-desktop
        ];
      in
      nixAi ++ termUi ++ monoTypography ++ niriDesktop ++ baseDev;
  };
}
