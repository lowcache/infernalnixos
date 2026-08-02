# Nix-on-Droid (`nixOnDroidConfigurations.default`)

The aarch64 Android target. Same flake, same `flake.lock`, same shared Home
Manager layer as volnix — see `home/common/`.

## What is shared vs. what is not

| Layer | Lives in | volnix | phone |
|---|---|---|---|
| fish (env, aliases, functions), git, starship, direnv, micro, core CLI | `home/common/` | yes | yes |
| niri / Noctalia / Wayland / GPU, sops-nix secrets, impermanence paths, systemd user services | `home/shell.nix`, `home/pkgs.nix`, `home/persist.nix` | yes | no |
| Termux shims, phone TMPDIR, `droid-*` aliases | `droid/` | no | yes |

`programs.fish.{shellInit,interactiveShellInit}` are `types.lines`, and
`shellAliases` / `functions` / `home.packages` are merging options, so each host
appends to the shared definitions rather than replacing them.

## Deploying

Nix-on-Droid builds on the device. volnix has no aarch64 emulation
(`boot.binfmt.emulatedSystems` is not set), so the laptop can evaluate this
configuration but cannot build it.

On the laptop:

```
make droid-check   # evaluate the phone's HM layer (aarch64) — catches option/typo errors
make droid-plan    # dry-run: what the phone would fetch vs. compile
```

On the phone, inside the Nix-on-Droid app. **Do the `nix.conf` step first** — see
`droid/nix.conf` for why:

```
mkdir -p ~/.config/nix
curl -sfL https://raw.githubusercontent.com/lowcache/volnixos/main/droid/nix.conf \
  -o ~/.config/nix/nix.conf

nix-on-droid switch --flake github:lowcache/volnixos
# or, from a local clone:
make droid-switch
```

Skipping it does not fail fast. Nix warns `ignoring substitute ... because it's
not signed by any of the keys`, silently falls back to building the llm-agents
set from source, and dies minutes later on
`python3.14-sqlalchemy-bigquery` — whose tarball cannot be unpacked under proot
(`tar: Cannot change mode ...`). The packages are all published and signed; the
key just was not trusted yet.

Both `make droid-check` and `nix-on-droid` itself pass `--impure`. That is not a
workaround on our side: upstream references the bootstrap `proot-termux` binary
with `builtins.storePath`, which pure evaluation rejects
(`nix-on-droid/nix-on-droid.sh` passes `--impure` for the same reason).

`make droid-check` targets the Home Manager layer specifically. The system layer
cannot be fully evaluated off-device: `modules/user.nix` upstream runs `id -u` /
`id -g` in an aarch64 derivation and imports the result (import-from-derivation),
so it needs a real aarch64 builder. That is device state, not configuration.

## Closure budget

Package choices in `home/common/packages.nix` are constrained by what has an
aarch64 substitute and by unpacked closure size — the phone has neither the CPU
nor the storage to absorb a desktop closure. Measured at the current lock:

| | source builds | download | unpacked |
|---|---|---|---|
| naive port of the desktop CLI set | `nodejs` from source | 158 MiB | 3906 MiB |
| `home/common` only | none | 54 MiB | 1329 MiB |
| `home/common` + `droid/agents.nix` | none | 363 MiB | 4788 MiB |

Storage is not the binding constraint on a 512 GB device — build time and RAM
are, which is why "zero source builds" is the number that matters. If you do
want a lean phone, drop `./agents.nix` from the `imports` in `droid/home.nix`;
nothing else depends on it.

**The agent layer requires `cache.numtide.com`**, declared in
`droid/default.nix`. Without it the `pkgs.llm-agents.*` packages have no
substitute and the phone compiles every one of them. `nix.substituters` and
`nix.trustedPublicKeys` are `listOf str`, so those entries append to
nix-on-droid's own defaults rather than replacing them.

The first row's difference is four packages, deliberately kept desktop-only:

- `nodejs` — no aarch64 substitute at this nixpkgs rev; the phone would compile it.
- `go` — ~300 MB for a toolchain a phone rarely needs.
- `pandoc` — Haskell toolchain (micro's `preview` plugin backend).
- `ripgrep-all` — drags in ffmpeg, poppler and tesseract.

Re-check with `make droid-plan` after changing `home/common/packages.nix`. Any
non-trivial derivation in the "will be built" list means the phone compiles it.

## Relationship to the phone-agent MCP server

Nix-on-Droid is **not** Termux. It ships as its own Android package,
`com.termux.nix`, with its own sandbox at `/data/data/com.termux.nix/files`. It
cannot read Termux's `$PREFIX`, and — this is the part that matters for
`nixos/phone-agent/` — it is not an authorized caller of the **Termux:API** app,
which allowlists `com.termux`.

So the current architecture stands: the phone-agent MCP server keeps running
under Termux, where `termux-sensor`, `termux-battery-status` and friends work,
and is reached over the network (Tailscale today; plain loopback also works,
since Android permits 127.0.0.1 between apps). Nix-on-Droid sits alongside it as
the declarative dev environment, not as a replacement host.

The `android-integration.*` options enabled in `default.nix` are a different
thing: they broadcast Android intents at Nix-on-Droid's *own* package, so
`termux-open`, `termux-setup-storage` and `termux-wake-lock` work without the
Termux app being involved at all.
