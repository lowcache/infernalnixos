{ config, pkgs, inputs, lib, ... }: {

  imports = [
    ./vms.nix
    ./windows-vm.nix

  ];

  # Boot loader & secure boot (kernel/perf config lives in
  # ./hardware/asus-ryzen-nvidia/kernel.nix)
  boot = {
    initrd.systemd.enable = true;
    loader = {
      systemd-boot = {
        enable = lib.mkForce false;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
  };

  networking = {
    hostName = "volnix";
    networkmanager = {
      enable = true;
      wifi.scanRandMacAddress = true;
    };
  };

  systemd = {
    oomd.enable = false;
    tmpfiles.rules = [
      "d /home/lowcache 0700 lowcache users"
      "d /home/lowcache/AppImage 0755 lowcache users"
      "d /home/lowcache/Storage/ai-generation 0755 lowcache users"
      "d /home/lowcache/Storage/ai-generation/fooocus 0755 lowcache users"
      "d /home/lowcache/Storage/ai-generation/forge 0755 lowcache users"
      "d /persist/var/lib/tailscale-vm 0700 root root"
      # Disk-backed build temp so nix builds never exhaust the 4G tmpfs root.
      "d /nix/tmp 1777 root root -"
    ];
    services = {
      #greetd.serviceConfig = {
      #StandardInput = "tty";
      #StandardOutput = "tty";
      #StandardError = "journal";
      #TTYReset = true;
      #TTYHangup = true;
      #TTYDeallocate = true;
      #};
      nix-daemon.serviceConfig.KillMode = "process";
      # Build temp on /nix (root-owned, nixbld-accessible) — never the RAM tmpfs.
      # Must NOT live under /home/lowcache (0700) or nixbld can't traverse it.
      nix-daemon.environment.TMPDIR = "/nix/tmp";
      decapitate-fuse-mounts = {
        description = "Force lazy unmount of xdg-document-portal FUSE to release /nix";
        before = [ "local-fs.target" ];
        wantedBy = [ "shutdown.target" "reboot.target" "halt.target" ];
        serviceConfig = {
          Type = "oneshot";
          DefaultDependencies = false;
          ExecStart = "${pkgs.coreutils}/bin/umount -f -l /run/user/1000/doc || true";
          ExecStopPost = "${pkgs.psmisc}/bin/killall -9 xdg-document-portal fusermount3";
        };
      };
      # Run Ollama as your user to avoid permission issues in ~/Storage
      ollama.serviceConfig = {
        User = "lowcache";
        Group = "users";
        ProtectHome = lib.mkForce false;
        Environment = [
          "OLLAMA_ORIGINS=*"
          "OLLAMA_FLASH_ATTENTION=1"
          "OLLAMA_NUM_PARALLEL=1"
          "CUDA_VISIBLE_DEVICES=0"
          "OLLAMA_KEEP_ALIVE=5m"
        ];
      };
      # Inject ffmpeg into open-webui's PATH environment for dynamic user execution
      open-webui.path = [ pkgs.ffmpeg ];
    };
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
      DefaultRestartSec = "1s";
    };
    user.settings.Manager.DefaultTimeoutStopSec = "5s";
  };
  users = {
    users = {
      root = {
        hashedPasswordFile = config.sops.secrets.root_password.path;
      };
      lowcache = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.user_password.path;
        extraGroups = [ "adbusers" "networkmanager" "wheel" "video" "docker" "uinput" ];
      };
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      user_password = {
        neededForUsers = true;
      };
      root_password = {
        neededForUsers = true;
      };
      gemini_api_key = {
        owner = "lowcache";
      };
      github_token = {
        owner = "lowcache";
      };
    };
  };
  programs = {
    # `make switch-detached` runs nixos-rebuild as root; nix's git fetcher
    # refuses the lowcache-owned repo without a safe.directory whitelist
    # (fails with "getting the HEAD of the Git tree ... exit code 254").
    git = {
      enable = true;
      config.safe.directory = [
        "/persist/home/lowcache/.nix-config"
        "/home/lowcache/.nix-config"
      ];
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        libgcc.lib
        libxcrypt-legacy
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxrender
        libxv
        libxcb
        openssl.out
        fuse3
        icu
        nss
        nspr
        atk
        gtk3
        at-spi2-atk
        at-spi2-core
        libdrm
        mesa
        libgbm
        glib
        pango
        cairo
        alsa-lib
        dbus
        curl
        expat
        # GPU / Graphics
        libvdpau
        libva
        vulkan-loader
        libGL
        egl-wayland
        wayland
        libxkbcommon
        linuxPackages.nvidia_x11.out
        cudaPackages.cuda_cudart
        cudaPackages.libcublas
        cudaPackages.nccl
        libglvnd
        mesa
        cups
      ];
    };
    niri.enable = true;
    appimage = {
      enable = true;
      binfmt = true;
    };
    kdeconnect.enable = true;
    fish.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
      liveRestore = false;
    };
    oci-containers = {
      backend = "docker";
      containers = {
        "fooocus" = {
          image = "ghcr.io/lllyasviel/fooocus:latest";
          autoStart = false;
          ports = [ "7865:7865" ];
          volumes = [ "/home/lowcache/Storage/ai-generation/fooocus:/content/data" ];
          environment = {
            CMDARGS = "--listen";
            DATADIR = "/content/data";
            config_path = "/content/data/config.txt";
            path_checkpoints = "/content/data/models/checkpoints/";
            path_loras = "/content/data/models/loras/";
            path_outputs = "/content/data/outputs/";
          };
          extraOptions = [ "--device" "nvidia.com/gpu=0" ];
        };
      };
    };
  };

  # Application Support
  services = {
    # Open WebUI Service
    open-webui = {
      enable = true;
      port = 8080;
      environment = {
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      };
    };
    upower.enable = true;
    # Ollama Service
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      home = "/home/lowcache";
      models = "/home/lowcache/Storage/ollama/models";
    };

    timesyncd.enable = true;
    geoclue2.enable = true;
    scx = {
      enable = false;
      scheduler = "scx_bpfland";
    };
    flatpak.enable = true;
    # dbus-broker (the uwsm default) is in use. A historical 2026-06-10 portal
    # failure on this host traced to the old Hyprland session's cap_sys_nice
    # wrapper leaking ambient CAP_SYS_NICE (not a dbus/pidfd issue) — moot now
    # that Hyprland is gone. See .memory/inbox/2026-06-12-portal-bug-real-root-cause.md.
    asusd.enable = true;
    supergfxd.enable = false;
    power-profiles-daemon.enable = false;
    logind.settings = {
      Login = {
        KillUserProcesses = true;
      };
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          # niri is the sole session. niri.desktop comes from programs.niri in
          # ./niri.nix; launched via uwsm (uwsm binary lives in systemPackages).
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions --cmd 'uwsm start niri.desktop'";
          user = "greeter";
        };
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  environment = {
    systemPackages =
      let
        base-utils = with pkgs; [
          sbctl
          cryptsetup
          wireguard-tools
          tor
          uwsm
          android-studio
          android-tools
          appimage-run
          vulkan-tools
          libva-utils
          nvd
          gnupg
          nvtopPackages.nvidia
          nvidia-vaapi-driver
          ffmpeg
          adwaita-icon-theme
          hicolor-icon-theme
          weylus
        ];
        nix-utils = with pkgs; [
          nh
          statix
          vulnix
          deadnix
          nix-diff
          nix-init
          manix
          nixfmt
          nixos-option
          nixos-shell
          styx
          tix
          nixmate
          optnix
          nix-index
          nvd
          searchix
          nurl
          autoflake
          flake-edit
          fh
          flake-checker
        ];
      in
      base-utils ++ nix-utils;
  };
  nix = {
    # Lix from nixpkgs (binary-cached, tracks nixpkgs updates). Replaces the
    # lix-project/nixos-module flake input, whose release branches lag behind
    # the lixPackageSets versions nixpkgs keeps around.
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "lowcache" ];
      auto-optimise-store = true;
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.lix.systems"
        "https://cuda-maintainers.cachix.org"
        "https://cache.numtide.com"
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.lix.systems:aBnZU3F19808R5N0sczBmsWwI5YI+433R9M2iS2Hcy4="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
      min-free = 536870912; # 512MB
      max-free = 1073741824; # 1GB
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  system.stateVersion = "24.11";

  time.timeZone = "America/Chicago";
}
