{
  config,
  pkgs,
  lib,
  username,
  ...
}:
{

  imports = [
    ./vms.nix
    ./windows-vm.nix
    ./phone-agent

  ];

  # Phone agent (S26 Ultra MCP integration, Phase 8). Bearer token is the
  # laptop's sops-materialized copy of the phone's token (matches the phone's
  # ~/.config/phone-agent/token). phoneTailscaleIP is stable per node key.
  phone-agent = {
    enable = true;
    phoneTailscaleIP = "100.101.229.9";
    tokenFile = config.sops.secrets.phone_agent_token.path;
  };

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
      wifi = {
        scanRandMacAddress = true;
        macAddress = "stable-ssid";
      };
      settings = {
        "connection-tether-lowprio" = {
          match-device = "driver:rndis_host,driver:cdc_ether,driver:cdc_ncm";
          "ipv4.route-metric" = 700;
        };
      };
    };
    # Anonymous-mode egress marking. Deliberately NOT networking.nftables.enable:
    # that disables the ip_tables module and breaks Docker + libvirt networking
    # on this host (nixpkgs #24318). Instead we add a mangle OUTPUT rule via the
    # existing iptables backend that marks packets owned by anon-user (UID 10000);
    # the anon-routing service policy-routes fwmark 0x1 to the Tor VM. Only
    # UID-10000 traffic is touched, so normal user/system traffic is unaffected.
    firewall = {
      # Reach Ollama (bound 0.0.0.0:11434) only from the tailscale MicroVM
      # guest, which DNATs tailnet :11434 → 192.168.101.1:11434 for the phone
      # agent. Interface-scoped: WAN stays closed, loopback is exempt.
      interfaces."vm-tailscale".allowedTCPPorts = [ 11434 ];
      extraCommands = ''
        iptables -t mangle -A OUTPUT -m owner --uid-owner 10000 -j MARK --set-mark 0x1
      '';
      extraStopCommands = ''
        iptables -t mangle -D OUTPUT -m owner --uid-owner 10000 -j MARK --set-mark 0x1 2>/dev/null || true
      '';
    };
  };

  systemd = {
    oomd.enable = false;
    tmpfiles.rules = [
      "d /home/${username} 0700 ${username} users"
      "d /home/${username}/AppImage 0755 ${username} users"
      "d /home/${username}/Storage/ai-generation 0755 ${username} users"
      "d /home/${username}/Storage/ai-generation/fooocus 0755 ${username} users"
      "d /home/${username}/Storage/ai-generation/forge 0755 ${username} users"
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
        wantedBy = [
          "shutdown.target"
          "reboot.target"
          "halt.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          DefaultDependencies = false;
          ExecStart = "${pkgs.coreutils}/bin/umount -f -l /run/user/1000/doc || true";
          ExecStopPost = "${pkgs.psmisc}/bin/killall -9 xdg-document-portal fusermount3";
        };
      };
      # Run Ollama as your user to avoid permission issues in ~/Storage
      ollama.serviceConfig = {
        User = username;
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
      # Policy routing for anonymous mode: fwmark 0x1 (set by the mangle rule in
      # networking.firewall) -> table 100 -> default via the net-gate Tor VM.
      # On-demand only (no wantedBy): pulled up by anonymous.target, so it never
      # races the VM tap at boot. table 100 is non-default — only marked packets
      # use it, so normal traffic is untouched.
      anon-routing = {
        description = "Policy routing for anonymous-mode egress (UID 10000 -> Tor VM)";
        after = [
          "network-online.target"
          "microvm@net-gate.service"
        ];
        wants = [ "network-online.target" ];
        partOf = [ "anonymous.target" ]; # torn down when anon mode is stopped
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "anon-routing-up" ''
            ${pkgs.iproute2}/bin/ip rule list | grep -q "fwmark 0x1 lookup 100" || \
              ${pkgs.iproute2}/bin/ip rule add fwmark 0x1 table 100
            ${pkgs.iproute2}/bin/ip route replace default via 192.168.100.2 table 100
          '';
          ExecStop = pkgs.writeShellScript "anon-routing-down" ''
            ${pkgs.iproute2}/bin/ip route flush table 100 2>/dev/null || true
            ${pkgs.iproute2}/bin/ip rule del fwmark 0x1 table 100 2>/dev/null || true
          '';
        };
      };
      # Readiness gate for anonymous.target: block until the VM's Tor SOCKS5 is
      # actually reachable (VM unit being 'active' != Tor bootstrapped), then
      # report status. Proxy-only — deliberately no DNS override (too disruptive).
      anon-socks-check = {
        description = "Wait for net-gate Tor SOCKS5 reachability (anonymous mode)";
        after = [ "microvm@net-gate.service" ];
        partOf = [ "anonymous.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "anon-socks-wait" ''
            for i in $(${pkgs.coreutils}/bin/seq 1 30); do
              if ${pkgs.coreutils}/bin/timeout 2 ${pkgs.bash}/bin/bash \
                  -c ": >/dev/tcp/192.168.100.2/9050" 2>/dev/null; then
                echo "Tor SOCKS5 reachable at 192.168.100.2:9050 — anonymous mode armed."
                exit 0
              fi
              ${pkgs.coreutils}/bin/sleep 1
            done
            echo "Timed out waiting for Tor SOCKS5 at 192.168.100.2:9050" >&2
            exit 1
          '';
        };
      };
    };
    settings.Manager = {
      DefaultTimeoutStopSec = "10s";
      DefaultRestartSec = "1s";
    };
    user.settings.Manager.DefaultTimeoutStopSec = "5s";
    # One-shot arm/disarm for anonymous mode. Manual/on-demand: no wantedBy, so
    # it never autostarts at boot. Pulls up the net-gate VM (if down), the egress
    # policy routing, and the SOCKS readiness check. Stopping it tears down the
    # partOf units (routing + check) but leaves the net-gate VM running, since the
    # VM is only `wants` here — it's still useful without anon mode.
    #   arm:    sudo systemctl start anonymous.target
    #   disarm: sudo systemctl stop  anonymous.target
    targets.anonymous = {
      description = "Anonymous mode: egress via the net-gate Tor VM (manual/on-demand)";
      wants = [
        "microvm@net-gate.service"
        "anon-routing.service"
        "anon-socks-check.service"
      ];
      after = [ "microvm@net-gate.service" ];
    };
  };
  users = {
    users = {
      root = {
        hashedPasswordFile = config.sops.secrets.root_password.path;
      };
      ${username} = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.user_password.path;
        extraGroups = [
          "adbusers"
          "networkmanager"
          "wheel"
          "video"
          "docker"
          "uinput"
        ];
      };
      # Anonymous-mode isolation UID. Processes launched as this user (via
      # `anon-run`) have their egress marked and policy-routed through the
      # net-gate Tor VM. Fixed UID 10000 so the firewall owner-match is stable.
      anon-user = {
        uid = 10000;
        isSystemUser = true;
        group = "nogroup";
        description = "UID for anonymous-mode app isolation";
      };
    };
  };

  sops = {
    defaultSopsFile = ./host-secrets.yaml;
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
        owner = username;
      };
      github_token = {
        owner = username;
      };
      # Buttondown API tokens, one per newsletter account — the two lists are
      # deliberately separate identities, so a single shared key would defeat
      # the separation at the only layer that still enforces it. Scoped in
      # Buttondown to emails:write / subscribers:none; ./newsletter.sh in each
      # blog repo only ever creates drafts, and a key that can also read the
      # subscriber list is a bigger blast radius than the script needs.
      #
      # Consumed by PATH (/run/secrets/...), never exported: the scripts read
      # BUTTONDOWN_API_KEY_FILE so the token stays out of the environment.
      buttondown_api_key_hotelevangelism = {
        owner = username;
      };
      # Cloudflare deploy token for `make deploy` in the blog repos. Needed
      # because wrangler stores its OAuth credentials under ~/.config/.wrangler,
      # which impermanence discards on every boot (home/persist.nix does not
      # list it), so an interactive `wrangler login` survives exactly until the
      # next reboot. A sops secret survives by construction rather than by
      # remembering to persist a directory.
      #
      # wrangler reads CLOUDFLARE_API_TOKEN from the environment and offers no
      # file-based alternative, so the blog Makefiles cat this path into the
      # environment of that one command rather than exporting it into the shell.
      cloudflare_api_token = {
        owner = username;
      };
      # Second Buttondown token, for Volatile Testimony. Separate from the
      # hotelevangelism key on purpose: the two lists are separate identities
      # with separate sending reputations, and one shared key would undo that
      # at the only layer still enforcing it.
      buttondown_api_key_volatiletestimony = {
        owner = username;
      };
      # Phone-agent bearer token (laptop -> phone MCP auth, scripts/verify.sh).
      # Placed at the exact path the client reads; sops re-materializes it at
      # activation every boot, so it survives the impermanence rollback of
      # ~/.config (which is not a persisted path — see home/persist.nix).
      phone_agent_token = {
        owner = username;
        path = "/home/${username}/.config/phone-agent/token";
        mode = "0400";
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
        "/persist/home/${username}/.nix-config"
        "/home/${username}/.nix-config"
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
          volumes = [ "/home/${username}/Storage/ai-generation/fooocus:/content/data" ];
          environment = {
            CMDARGS = "--listen";
            DATADIR = "/content/data";
            config_path = "/content/data/config.txt";
            path_checkpoints = "/content/data/models/checkpoints/";
            path_loras = "/content/data/models/loras/";
            path_outputs = "/content/data/outputs/";
          };
          extraOptions = [
            "--device"
            "nvidia.com/gpu=0"
          ];
        };
      };
    };
    waydroid.enable = true;
  };

  # Application Support
  services = {
    # Vial keyboard configurator: unprivileged hidraw access for Vial-enabled
    # keyboards (matched by the vial:f64c2b3c magic in the USB serial).
    udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
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
      home = "/home/${username}";
      modelsDir = "/home/${username}/Storage/ollama/models";
      # Bind all interfaces so the tailscale MicroVM guest (192.168.101.2) can
      # reach it on 192.168.101.1:11434; loopback consumers (open-webui) keep
      # working. WAN exposure is prevented by the interface-scoped firewall
      # rule below — 11434 is opened ONLY on vm-tailscale, not globally.
      host = "0.0.0.0";
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
    #    resolved = {
    #      enable = true;
    #      dnsovertls = "opportunistic";
    #      fallbackDns = [ "1.1.1.1#cloudflare.dns.com" "9.9.9.9#dns.quad9.net" ];
    #    };
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
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        username
      ];
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
      android_sdk.accept_license = true;
    };
  };

  system.stateVersion = "24.11";

  time.timeZone = "America/Chicago";
}
