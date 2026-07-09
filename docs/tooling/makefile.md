# Makefile & Operations

The [`Makefile`](https://github.com/lowcache/volnixos/blob/main/Makefile) is the **canonical**
operations interface — prefer it over ad-hoc `nixos-rebuild` invocations. `HOST` defaults to `volnix`
(the only host). Run `make help` for the live list.

## System

| Target              | Action                                              |
| :------------------ | :-------------------------------------------------- |
| `make switch`       | Rebuild and switch the live system (needs `sudo`)   |
| `make switch-detached`| Switch as a detached system unit (survives mid-rebuild session teardown) |
| `make build`        | Build the configuration without switching           |
| `make test`         | Temporarily activate (no boot entry)                |
| `make dry-activate` | Preview service transitions                         |
| `make boot`         | Stage the rebuild for the next boot                 |

## MicroVM guests

| Target              | Action                          |
| :------------------ | :------------------------------ |
| `make run-netgate`  | Start the Tor net-gate runner   |
| `make run-tailscale`| Start the Tailscale-vm runner   |

## Flake & maintenance

| Target               | Action                                          |
| :------------------- | :--------------------------------------------- |
| `make check`         | `nix flake check`                               |
| `make fmt`           | Format all `.nix` with `nixpkgs-fmt`            |
| `make update`        | Update all flake inputs                          |
| `make update-nixpkgs`| Update only `nixpkgs`                            |
| `make trash`         | Delete >7d system generations + GC the store     |
| `make git`           | Interactively stage, commit, and push changes  |

## Dotfiles subtree

Independent history for `dots/` in a single repo — see [Dotfiles](../reference/dotfiles.md):

```bash
make dots-log | dots-split | dots-remote URL=… | dots-push | dots-pull
```

## Themes

The JSON colorscheme engine (see [Theming](../desktop/theming.md)):

```bash
make theme-list
make theme-apply THEME=<name>
make theme-check THEME=<name>
make theme-new   NAME="My Theme" [COLORS="#a #b …"] [FROM=<file>] [APPLY=1] [FORCE=1]
```

!!! tip "Recommended flow"
    `make check` → `make build` → `make switch`. Use `make dry-activate` first when changing services
    to preview restarts.
