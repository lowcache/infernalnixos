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
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.url = "git+https://git.lix.systems/lix-project/lix";
    };
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
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , microvm
    , volinit
    , nur
    , llm-agents
    , ...
    }@inputs:
    {
      nixosConfigurations.volnix = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          {
            nixpkgs.overlays = [
              inputs.nix-cachyos-kernel.overlays.pinned
              inputs.nur.overlays.default
              inputs.llm-agents.overlays.default
            ];
          }
          ./nixos/configuration.nix
          ./nixos/hardware-configuration.nix
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.impermanence.nixosModules.impermanence
          inputs.lix-module.nixosModules.default
          inputs.sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.lowcache = import ./home;
          }
        ];
      };

      # Add this to allow building/running the VM packages
      packages.x86_64-linux.net-gate =
        self.nixosConfigurations.volnix.config.microvm.vms.net-gate.config.config.microvm.declaredRunner;
      packages.x86_64-linux.tailscale-vm =
        self.nixosConfigurations.volnix.config.microvm.vms.tailscale.config.config.microvm.declaredRunner;
    };
}
