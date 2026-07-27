{ config, ... }: {

  xdg = {
    enable = true;
    # Move the XDG cache root off the 4G tmpfs onto the roomy ~/Storage volume.
    # This sets XDG_CACHE_HOME session-wide, so pip/llmfit/etc. all
    # cache to Storage by default instead of filling root (see home/default.nix).
    cacheHome = "${config.home.homeDirectory}/Storage/.cache";
    configFile = {
      # Color engine (apply_theme.py + themes/) for the niri/Noctalia session.
      "color-engine".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/color-engine";
      # niri + Noctalia v5. Live-edit symlinks; Home Manager writes no files here
      # (see home/noctalia.nix), so no collision.
      "niri".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/niri";
      "noctalia".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/noctalia";
      "kitty".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/kitty";
      "fastfetch".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/fastfetch";
      "cava".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/cava";
      "fuzzel".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/fuzzel";
      "wlogout".source =
        config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/wlogout";
      # force: Noctalia natively themes starship and replaces this symlink with a
      # real file (its [palettes.noctalia] block), which made HM refuse to clobber
      # and failed the switch. force lets HM reclaim the symlink each activation.
      "starship.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config/dots/starship/starship.toml";
        force = true;
      };
      "kritarc".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Storage/krita-master/kritarc";
      "kritadisplayrc".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Storage/krita-master/kritadisplayrc";
    };
  };

  home = {
    file = {
      ".local/share/krita".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Storage/krita-master/krita";
      "Pictures/fromAi/outputs".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Storage/ai-generation/fooocus/outputs";
      # Non-hidden alias of the repo: antigravity (agy) rejects hidden paths as
      # workspace folders but does not resolve symlinks, mitigatef with workdir 
      # ~/volnix to get full workspace registration.
      "volnix" = {
        source = config.lib.file.mkOutOfStoreSymlink "/persist${config.home.homeDirectory}/.nix-config";
        force = true;
      };
    };
    persistence."/persist" = {
      directories =
        let
          dotfiles = [
            ".npm"
            ".cargo"
            ".rustup"
            ".ssh"
            ".ollama"
            ".gnupg"
            ".claude"
            ".codex"
            ".gemini"
            ".nix-config"
            ".vscode-oss"
            ".antigravity"
            ".antigravity-ide"
            ".solc-select"
            ".foundry"
            ".ZAP"
            ".nix-profile"
          ];
          config = [
            ".config/dconf"
            ".config/VSCodium"
            ".config/Antigravity"
            ".config/Antigravity IDE"
            ".config/Google"
            ".config/BraveSoftware"
            ".config/micro"
            ".config/mcp-gateway"
            ".config/systemd/user"
            ".config/sops"
            ".config/memd"
          ];
          # Note: with XDG_CACHE_HOME redirected to ~/Storage/.cache (see home/default.nix),
          # caches no longer land on the 4G tmpfs by default. These entries remain as a
          # safety net for any app that hardcodes ~/.cache and ignores XDG. ".cache/llmfit"
          # added after it (an XDG-ignoring cache) filled root tmpfs to 100% on 2026-06-16.
          cache = [
            ".cache/pip"
            ".cache/noctalia"
            ".cache/nvidia"
            ".cache/llmfit"
          ];
          local = [
            ".local/share/npm-global"
            ".local/share/go"
            ".local/share/gem"
            ".local/share/fish"
            ".local/share/direnv"
            ".local/share/fonts"
            ".local/share/noctalia"
            ".local/share/keyrings"
            ".local/share/Google"
            ".local/share/flatpak"
            ".local/share/applications"
            ".local/share/Antigravity-x64"
            ".local/share/Antigravity IDE"
            ".local/bin"
            ".local/state/noctalia"
            ".local/state/wireplumber"
            ".local/state/memd"
          ];
          flatpak-var = [
            ".var/app"
          ];
          home-dirs = [
            "CodeRepo"
            "Documents"
            "unDevel"
            "Downloads"
            "Pictures"
            "Projects"
            "AppImage"
            "ZAP-Sessions"
            ".bin"
          ];
        in
        dotfiles ++ config ++ cache ++ local ++ flatpak-var ++ home-dirs;
      # Single files in $HOME that must survive the tmpfs wipe.
      # ~/.claude.json holds Claude Code config/state and lives OUTSIDE ~/.claude.
      files = [
        ".claude.json"
      ];
    };
  };
}
