{
  description = "Vol NixOS - Vol(atile) Nix OS by LowCache [github.com/lowcache/volnixos.git]";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Noctalia v5 (C++/native shell). follows nixpkgs per decision (source build,
    # no Cachix). Wired via home/noctalia.nix (homeModules.default).
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned v4.7.7 backup (emergency rollback). Kept COMMENTED so an unused input
    # can't fail `nix flake lock`. To use: uncomment, lock, point home/noctalia.nix
    # package at inputs.noctalia-stable.packages.${system}.default.
    # noctalia-stable = {
    #   url = "github:noctalia-dev/noctalia?ref=v4.7.7";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    # lix-module input removed: nixpkgs ships lix natively (lixPackageSets) and
    # the module's release branches lag nixpkgs' supported versions (release-2.93
    # vs nixpkgs stable 2.95). nix.package is set in nixos/configuration.nix.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    volinit = {
      url = "github:lowcache/volinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    memd = {
      url = "github:lowcache/memd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nix-on-Droid: the aarch64 Android target (`nixOnDroidConfigurations.default`).
    # No release branch is current — release-24.05 is the newest tag and it is
    # ~2 years behind, so track master and pin nixpkgs/home-manager to ours so the
    # phone and volnix evaluate against the same package set.
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        # Docs/formatter-only inputs. We never evaluate nix-on-droid's own
        # `formatter`/`checks`/docs outputs, so drop them rather than carry
        # extra locked revisions the phone would have to resolve.
        nix-formatter-pack.follows = "";
        nmd.follows = "";
        nixpkgs-docs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      username = "lowcache";
      system = "x86_64-linux";
      droidSystem = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations.volnix = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs username; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          {
            nixpkgs.overlays = [
              inputs.nix-cachyos-kernel.overlays.pinned
              inputs.nur.overlays.default
              inputs.llm-agents.overlays.shared-nixpkgs
              (import ./nixos/overlays/brave.nix)
              (import ./nixos/overlays/pandas-stubs.nix)
              (import ./nixos/overlays/niri.nix)
              (import ./nixos/overlays/ollama.nix)
            ];
          }
          ./nixos/configuration.nix
          ./nixos/hardware-configuration.nix
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.impermanence.nixosModules.impermanence
          inputs.sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.${username} = import ./home;
            };
          }
        ];
      };

      # Nix-on-Droid target. Built and switched ON THE PHONE
      # (`nix-on-droid switch --flake .`) — there is no aarch64 emulation on
      # volnix, so the laptop can only evaluate this, not build it
      # (`make droid-check`).
      nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          system = droidSystem;
          overlays = [
            # Recommended by upstream: supplies the on-device packages
            # (proot-static, termux shims) the nix-on-droid modules reference.
            inputs.nix-on-droid.overlays.default
            # Same overlay volnix uses, so `pkgs.llm-agents.*` resolves on the
            # phone too. llm-agents.nix builds aarch64-linux; the substituter it
            # publishes to is declared in droid/default.nix.
            inputs.llm-agents.overlays.shared-nixpkgs
          ];
          config.allowUnfree = true;
        };
        modules = [ ./droid ];
        home-manager-path = home-manager.outPath;
      };

      # Add this to allow building/running the VM packages
      packages.${system} = {
        net-gate =
          self.nixosConfigurations.volnix.config.microvm.vms.net-gate.config.config.microvm.declaredRunner;
        tailscale-vm =
          self.nixosConfigurations.volnix.config.microvm.vms.tailscale.config.config.microvm.declaredRunner;
      };

      # `nix fmt` — nixfmt (RFC 166, the official formatter), treefmt-wrapped so
      # it formats the whole tree and respects the git index (untracked files
      # like dots/gemini worktrees are skipped).
      formatter.${system} = pkgs.nixfmt-tree;

      # `nix flake check` gates: formatting + lint. ${self} is the git-tracked
      # source only, so generated/untracked .nix files are out of scope.
      checks.${system} = {
        formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
          find ${self} -name '*.nix' -exec nixfmt --check {} +
          touch $out
        '';
        lint =
          pkgs.runCommand "check-lint"
            {
              nativeBuildInputs = [
                pkgs.statix
                pkgs.deadnix
              ];
            }
            ''
              statix check ${self}
              deadnix --fail ${self}
              touch $out
            '';
      };
    };
}
