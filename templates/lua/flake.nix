{
  description = "Lua development environment: interpreter + lint/format toolchain for plugin work";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # =====================================================================
      # Project knobs.
      # =====================================================================

      # Interpreter, as a nixpkgs attribute name.
      #
      # Verified against the noctalia community-plugin harnesses
      # (drive-health, `make unit`): lua5_4 PASSES, luajit PASSES,
      # lua5_1 FAILS. Do not drop to "lua5_1" without re-running the suite.
      luaAttr = "lua5_4";

      # Extra tools on PATH, as nixpkgs attribute names. shellcheck matters
      # more than it looks: plugin Makefiles tend to guard it behind
      # `if command -v shellcheck`, so without it on PATH the lint step
      # silently passes instead of running.
      extraTools = [
        "shellcheck"
        "stylua"
        "lua-language-server"
      ];

      # Offline gates for `nix flake check`. See the shared note in the README:
      # one derivation per entry, empty by default.
      #   checkCommands = { unit = "make unit"; lint = "luacheck ."; };
      #
      # Keep gates to the hermetic subset. `make unit` is pure Lua and runs in
      # the sandbox; a target needing host systemd or man pages never will.
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
          pkgs.${luaAttr}
          # NOT pkgs.luarocks -- that attribute is built against lua5.2
          # regardless of luaAttr, so rocks would install into a tree the
          # shell's interpreter never reads.
          pkgs.${luaAttr}.pkgs.luarocks
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
      # No packages output. Lua plugins are interpreted and loaded by a host
      # (neovim, noctalia); there is nothing to build into the store.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = toolchain pkgs;

          shellHook = ''
            echo "$(lua -v 2>&1)  |  shellcheck, stylua, lua-language-server on PATH"
          '';
        };
      });

      checks = forAllSystems mkChecks;
    };
}
