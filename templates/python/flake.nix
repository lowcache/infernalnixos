{
  description = "Python development environment: interpreter + test/lint toolchain";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # =====================================================================
      # Project knobs.
      # =====================================================================

      # Interpreter, as a nixpkgs attribute name. "python3" tracks the nixpkgs
      # default; pin with "python312", "python313" when a dep is version-bound.
      pythonAttr = "python3";

      # Python packages pulled from nixpkgs, as `pythonPackages` attribute
      # names. These are the ones Nix provides -- anything not packaged in
      # nixpkgs still belongs in a venv (see README).
      pythonPkgs = [
        "pytest"
        "ruff"
      ];

      # Non-Python tools on PATH.
      extraTools = [ "git" ];

      # Offline gates for `nix flake check`. See the shared note in the README:
      # one derivation per entry, empty by default.
      #   checkCommands = { tests = "pytest tests/ -q"; lint = "ruff check ."; };
      checkCommands = { };

      # =====================================================================

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      toolchain =
        pkgs:
        [
          (pkgs.${pythonAttr}.withPackages (ps: map (name: ps.${name}) pythonPkgs))
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
            ${command}
            touch $out
          ''
        ) checkCommands;
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = toolchain pkgs;

          # PYTHONPATH is left alone on purpose: withPackages already wires the
          # interpreter, and exporting it leaks this env into any other python
          # invoked from the shell.
          shellHook = ''
            export PYTHONDONTWRITEBYTECODE=1
          '';
        };
      });

      checks = forAllSystems mkChecks;
    };
}
