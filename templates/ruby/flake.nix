{
  description = "Ruby development environment: bundler devShell + reproducible bundlerEnv build";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # =====================================================================
      # Project knobs -- the only lines most projects need to touch.
      # =====================================================================

      # Ruby version, as a nixpkgs attribute name. "ruby" tracks the nixpkgs
      # default (3.4.x today). Pin explicitly when a gem is version-sensitive:
      # "ruby_3_3", "ruby_3_4", "ruby_4_0".
      rubyAttr = "ruby";

      # Native libraries the gems' C extensions link against, as nixpkgs
      # attribute names. rmagick -> "imagemagick", pg -> "postgresql",
      # sqlite3 -> "sqlite", nokogiri -> "libxml2" and "libxslt".
      # Named as strings rather than taken from a `pkgs:` lambda so the file
      # stays clean under `deadnix --fail`.
      nativeLibs = [ ];

      # Offline gates for `nix flake check`. See the shared note in the README:
      # one derivation per entry, empty by default.
      #   checkCommands = { spec = "bundle exec rspec"; lint = "rubocop"; };
      checkCommands = { };

      # =====================================================================

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # One list, used by both the shell and the gates, so they cannot drift.
      toolchain =
        pkgs:
        [
          pkgs.${rubyAttr}
          pkgs.bundix
          pkgs.pkg-config
        ]
        ++ map (name: pkgs.${name}) nativeLibs;

      # Gates run against a writable copy, not the read-only store path: a
      # suite that writes so much as a temp file fails confusingly otherwise.
      mkChecks =
        pkgs:
        builtins.mapAttrs (
          name: command:
          pkgs.runCommand "check-${name}" { nativeBuildInputs = toolchain pkgs; } ''
            cp -r ${./.} src
            chmod -R u+w src
            cd src
            ${command}
            touch $out
          ''
        ) checkCommands;
    in
    {
      # Layer 1: iteration. `bundle install` compiles native extensions against
      # the Nix-provided libraries and drops gems in ./vendor/bundle.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = toolchain pkgs;

          # Keep every gem in-tree, so nothing leaks into ~/.gem and the
          # project stays disposable (`rm -rf vendor .gem`).
          #
          # BUNDLE_BIN is deliberately NOT set. It makes bundler write a `bundle`
          # binstub into vendor/bin; with that directory on PATH, bundler starts
          # shadowing itself, and the reset above then deletes the `bundle` on
          # PATH. Reach binaries through `bundle exec` instead.
          shellHook = ''
            export BUNDLE_PATH="$PWD/vendor/bundle"
            export GEM_HOME="$PWD/.gem"
            export PATH="$GEM_HOME/bin:$PATH"
          '';
        };
      });

      checks = forAllSystems mkChecks;

      # Layer 2: reproducible build. Activates once `bundix` has written
      # gemset.nix -- guarded, because bundlerEnv demands that file at
      # evaluation time and a freshly-initialised project has no gems yet.
      #
      # Gems needing extra build inputs are usually handled by nixpkgs'
      # defaultGemConfig (rmagick, pg, nokogiri and friends are covered).
      # For one that is not, pass `gemConfig = pkgs.defaultGemConfig // { ... }`.
      packages = forAllSystems (
        pkgs:
        nixpkgs.lib.optionalAttrs (builtins.pathExists ./gemset.nix) {
          default = pkgs.bundlerEnv {
            name = "ruby-env";
            ruby = pkgs.${rubyAttr};
            gemdir = ./.;
          };
        }
      );
    };
}
