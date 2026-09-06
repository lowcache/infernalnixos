{
  description = "Hugo site: hugo + go toolchain, wrangler deploy, reproducible site build";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # =====================================================================
      # Project knobs.
      # =====================================================================

      # Tools beyond the hugo/go/wrangler core, as nixpkgs attribute names.
      # Observed in practice: "jq", "pagefind" (search index), "python3".
      # Strings rather than a `pkgs:` lambda so an empty list stays clean
      # under `deadnix --fail`.
      extraTools = [ ];

      # Passed to `hugo` when building packages.default.
      hugoFlags = "--minify";

      # Offline gates for `nix flake check`. See the shared note in the README:
      # one derivation per entry, empty by default.
      #   checkCommands = { build = "hugo --minify --destination $TMPDIR/out"; };
      #
      # A theme pulled as a Hugo Module is fetched over the network, which the
      # sandbox denies; gate a site like that only once its modules are vendored.
      checkCommands = { };

      # =====================================================================

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # hugo needs go on PATH for Hugo Modules (go.mod-based themes), which is
      # why `go` is core here and not an extra.
      toolchain =
        pkgs:
        [
          pkgs.hugo
          pkgs.go
          pkgs.wrangler
        ]
        ++ map (name: pkgs.${name}) extraTools;

      mkChecks =
        pkgs:
        builtins.mapAttrs (
          name: command:
          pkgs.runCommand "check-${name}" { nativeBuildInputs = toolchain pkgs; } ''
            cp -r ${./.} src
            chmod -R u+w src
            cd src
            export HUGO_CACHEDIR=$TMPDIR/hugo-cache
            ${command}
            touch $out
          ''
        ) checkCommands;
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = toolchain pkgs;

          shellHook = ''
            echo "hugo $(hugo version | cut -d' ' -f2)  |  make serve / build / deploy"
          '';
        };
      });

      checks = forAllSystems mkChecks;

      # Reproducible site build. Themes vendored as Hugo Modules need network
      # access at build time, which a Nix sandbox denies -- for those, keep
      # using `make build` in the devShell and treat this as the CI path only
      # after committing the module cache.
      packages = forAllSystems (pkgs: {
        default = pkgs.stdenvNoCC.mkDerivation {
          name = "site";
          src = ./.;
          nativeBuildInputs = toolchain pkgs;
          buildPhase = ''
            export HUGO_CACHEDIR=$TMPDIR/hugo-cache
            hugo ${hugoFlags} --destination $TMPDIR/public
          '';
          installPhase = ''
            cp -r $TMPDIR/public $out
          '';
        };
      });
    };
}
