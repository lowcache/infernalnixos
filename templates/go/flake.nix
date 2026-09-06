{
  description = "Go development environment: toolchain, LSP, and a guarded module build";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # =====================================================================
      # Project knobs.
      # =====================================================================

      # Module name, used only to name the built binary.
      pname = "app";

      # Hash over the module dependencies. `null` is correct and complete for a
      # module with no external deps. For one that has deps: set this to
      # nixpkgs.lib.fakeHash, run `nix build .#default`, and paste back the hash
      # the failure reports.
      vendorHash = null;

      # Extra tools beyond the go toolchain, as nixpkgs attribute names.
      extraTools = [
        "gopls"
        "go-tools"
      ];

      # Offline gates for `nix flake check`. See the shared note in the README:
      # one derivation per entry, empty by default.
      #   checkCommands = { vet = "go vet ./..."; test = "go test ./..."; };
      #
      # Go gates need the module cache, which the sandbox has no network for.
      # Vendor deps (`go mod vendor`) or keep gates to dependency-free packages.
      checkCommands = { };

      # =====================================================================

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      toolchain = pkgs: [ pkgs.go ] ++ map (name: pkgs.${name}) extraTools;

      mkChecks =
        pkgs:
        builtins.mapAttrs (
          name: command:
          pkgs.runCommand "check-${name}"
            {
              nativeBuildInputs = toolchain pkgs;
            }
            ''
              cp -r ${./.} src
              chmod -R u+w src
              cd src
              export GOFLAGS=-mod=vendor
              export GOCACHE=$TMPDIR/go-build
              export GOPATH=$TMPDIR/go
              ${command}
              touch $out
            ''
        ) checkCommands;
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = toolchain pkgs;

          # Keep the module and build caches in-tree so the project stays
          # disposable and nothing lands in ~/go.
          shellHook = ''
            export GOPATH="$PWD/.go"
            export GOMODCACHE="$GOPATH/pkg/mod"
            export GOBIN="$GOPATH/bin"
            export PATH="$GOBIN:$PATH"
          '';
        };
      });

      checks = forAllSystems mkChecks;

      packages = forAllSystems (
        pkgs:
        nixpkgs.lib.optionalAttrs (builtins.pathExists ./go.mod) {
          default = pkgs.buildGoModule {
            inherit pname vendorHash;
            version = "0.0.0";
            src = ./.;
          };
        }
      );
    };
}
