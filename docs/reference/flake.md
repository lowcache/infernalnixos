# Flake Inputs & Outputs

[`flake.nix`](https://github.com/lowcache/volnixos/blob/main/flake.nix) tracks `nixpkgs` on
`nixos-unstable` and composes the system from the inputs below. Most `*.nix` modules pin
`inputs.nixpkgs.follows = "nixpkgs"` to keep a single nixpkgs in the closure.

## Inputs

| Input                | Source                                   | Role                                   |
| :------------------- | :--------------------------------------- | :------------------------------------- |
| `nixpkgs`            | `nixos/nixpkgs/nixos-unstable`           | Package set                            |
| `home-manager`       | `nix-community/home-manager`             | User environment                       |
| `nixos-hardware`     | `NixOS/nixos-hardware`                    | Hardware profiles                      |
| `nix-cachyos-kernel` | `xddxdd/nix-cachyos-kernel`              | CachyOS kernel overlay (`pinned`)      |
| `impermanence`       | `nix-community/impermanence`             | Ephemeral root / `/persist`            |
| `lanzaboote`         | `nix-community/lanzaboote`               | UEFI Secure Boot                       |
| `microvm`            | `astro/microvm.nix`                       | Isolated VM guests                     |
| `noctalia`           | `github:noctalia-dev/noctalia`           | Noctalia v5 desktop shell              |
| `lix-module`         | `git.lix.systems/.../nixos-module`       | Lix daemon (+ `lix` input)             |
| `sops-nix`           | `Mic92/sops-nix`                          | Encrypted secrets                      |
| `volinit`            | `lowcache/volinit`                        | Shell welcome banner                   |
| `nur`                | `nix-community/NUR`                       | Community overlay                      |
| `llm-agents`         | `numtide/llm-agents.nix`                  | AI agent tooling overlay               |

## Overlays

Applied in `flake.nix`:

```nix
nixpkgs.overlays = [
  inputs.nix-cachyos-kernel.overlays.pinned   # volnix only
  inputs.nur.overlays.default
  inputs.llm-agents.overlays.default
];
```

## Outputs

```mermaid
graph TD
    F["flake.nix"] --> V["nixosConfigurations.volnix"]
    F --> NG["packages.x86_64-linux.net-gate"]
    F --> TS["packages.x86_64-linux.tailscale-vm"]
    V --> HM["home-manager.users.lowcache → ./home"]
```

| Output                                  | Description                                   |
| :-------------------------------------- | :-------------------------------------------- |
| `nixosConfigurations.volnix`            | The host (`x86_64-linux`)                     |
| `packages.x86_64-linux.net-gate`        | Tor MicroVM runner (`nix run .#net-gate`)     |
| `packages.x86_64-linux.tailscale-vm`    | Tailscale MicroVM runner                      |

Both hosts wire Home Manager as a NixOS module with `useGlobalPkgs` and `useUserPackages`, passing
`inputs` through `extraSpecialArgs`.

## Maintenance

```bash
make check            # nix flake check
make update           # nix flake update (all inputs)
make update-nixpkgs   # nix flake update nixpkgs
nix flake update volinit
```

!!! warning "Lix pinning"
    `lix-module` carries an `inputs.lix.url` override tracking Lix `main`, built from source. Do not
    drop the override without re-verifying evaluation. See [Architecture](../architecture/index.md).
