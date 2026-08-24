# Nix-on-Droid (`nixOnDroidConfigurations.default`)

The aarch64 Android target. Same flake, same `flake.lock`, same shared Home
Manager layer as volnix — see `home/common/`.

## The phone is pinned to nixos-25.11, and must stay there

`flake.nix` gives the droid output its own `nixpkgs-droid` / `home-manager-droid`
input pair instead of following our unstable. This is load-bearing, not tidiness.

glibc 2.42 reimplemented `isatty()` / `tcgetattr()` on top of the **`TCGETS2`**
ioctl (termios2, arbitrary baud rates). Android's SELinux ioctl allowlist for
`untrusted_app` permits `TCGETS` but has never included `TCGETS2`, so on-device
it returns `EACCES`. Every glibc-2.42 binary therefore concludes it has no
terminal. bash and fish start, decide they are non-interactive, print no prompt,
and read commands silently from the pty — which is indistinguishable from a hang
until you redirect stdout and discover your keystrokes were executing all along.

Measured on a live pty (Android 16, proot-termux 5.1.0, `/dev/pts/0`):

```
ioctl TCGETS  0x5401      OK        ioctl TIOCGWINSZ 0x5413  OK
ioctl TCGETS2 0x802C542A  EACCES    ioctl TIOCGPGRP  0x540F  OK
tty (coreutils 9.5,  glibc 2.40) -> /dev/pts/0
tty (coreutils 9.11, glibc 2.42) -> not a tty
python3.14 (glibc 2.42): os.isatty(0) -> False
```

Same program, two glibcs, opposite answers. That isolates glibc and clears bash,
fish, readline, job control, proot, closure size and everything in `home/common`
— all of which were tested individually and are innocent.

glibc sits at the root of the package graph, so patching it means rebuilding all
of nixpkgs on a phone. nixos-25.11 ships glibc 2.40, uses `TCGETS`, and stays
fully cached.

Symptom to recognise if the pin is ever dropped: the app opens, prints the motd,
and shows a bare cursor with no prompt. It is not frozen. Type `echo hi > /sdcard/x`
and the file appears. Unpin only once glibc falls back to `TCGETS` when `TCGETS2`
is refused.

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

That step is vestigial as of 2026-08-03 and I am keeping it for the same reason I
am keeping the substituter entry itself — see "Closure budget". What it used to
prevent: skipping it did not fail fast. Nix warned `ignoring substitute ...
because it's not signed by any of the keys`, silently fell back to building the
llm-agents set from source, and died minutes later on
`python3.14-sqlalchemy-bigquery` — whose tarball cannot be unpacked under proot
(`tar: Cannot change mode ...`). The packages were all published and signed; the
key just was not trusted yet. The agent layer no longer installs any of them, so
there is nothing left for that cache to serve.

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
nor the storage to absorb a desktop closure.

**The MiB figures below are stale — treat them as historical.** Taken 2026-08-02;
every row predates the tree it describes. `droid/agents.nix` changed 2026-08-03
(dropped `llm-agents`, added `opencode`, `rtk`, `mcp-gateway`) and
`home/common/` changed 2026-08-14. They are also laptop-measured, so the
download/unpacked columns describe what volnix's store is missing, not what the
phone would pull. Only an on-device run gives a comparable number.

| | source builds | download | unpacked |
|---|---|---|---|
| naive port of the desktop CLI set | `nodejs` from source | 158 MiB | 3906 MiB |
| `home/common` only | none | 54 MiB | 1329 MiB |
| `home/common` + `droid/agents.nix` | none | 363 MiB | 4788 MiB |

The derivation count *is* portable, because it comes from evaluation rather than
from store contents. At the current lock, `make droid-plan` reports **104
derivations to build**, and the shape is what it should be:

| | count | |
|---|---|---|
| fish completions | 57 | glue |
| home-manager session/activation glue | 25 | glue |
| build-time helpers (`pythoncheck.sh`, cargo vendor utils, …) | ~14 | glue |
| `rtk` 0.44.2, `mcp-gateway` 3.4.0 | 2 (+2 vendor) | the deliberate on-device Rust builds |
| `claude-code` 2.1.140 | 1 | one npm derivation, cheap |

No plain nixpkgs package appears in that list, which is the invariant to hold.
If one does, the phone is about to compile it.

Storage is not the binding constraint on a 512 GB device — build time and RAM
are, which is why "zero source builds" is the number that matters. If you do
want a lean phone, drop `./agents.nix` from the `imports` in `droid/home.nix`;
nothing else depends on it.

`cache.numtide.com` is declared in `droid/default.nix` and currently serves
nothing. It mattered when the agent layer installed the `pkgs.llm-agents.*` set:
without it those packages had no substitute and the phone compiled every one of
them. I dropped that set on 2026-08-03 (the 25.11 pin hashes differently from
what numtide publishes, so nothing substituted anyway), which leaves the entry
costing one extra 404 per substitution query. I am keeping it because it is
correct and signed if the pin ever lifts. `nix.substituters` and
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

The `android-integration.*` options are a different thing: they broadcast Android
intents at Nix-on-Droid's *own* package, so they work with the Termux app not
installed at all. They are **on** as of 2026-08-03 — `xdg-open` (claude's OAuth
browser flow), `termux-wake-lock` and `termux-wake-unlock`. See
"Android integration" below for what it took.

## Android integration

`xdg-open`, `termux-wake-lock` and `termux-wake-unlock` are on, switched and
running since 2026-08-03. Getting there took two fixes, and having only one of
them looks exactly like having neither.

Everything in the `android-integration` module needs `termux-am`, which is one of
nix-on-droid's own packages rather than a nixpkgs one — cmake, built from source.
Upstream publishes it on `nix-on-droid.cachix.org` but only against upstream's
nixpkgs, so at the 25.11 pin the hash does not match and the phone has to compile
it. It is a `fetchFromGitHub` source, so it hit the proot `_defaultUnpack` failure
that `droid/backports.nix` documents at length: `cp` creates the destination
directory and then chmods it, and proot returns ENOENT for that chmod. The
`prootUnpack` override there fixes the build.

That is not sufficient, and this is the part that cost me a second round.
Upstream's `android-integration.nix` runs `pkgs.callPackage` on the
`termux-am` / `termux-tools` derivation files **directly**, which never consults
the overlay — so the patched packages get built and then ignored. `default.nix`
therefore disables upstream's module and imports a local copy:

```nix
disabledModules = [ "${nix-on-droid}/modules/environment/android-integration.nix" ];
imports = [ ./android-integration.nix ];
```

`droid/android-integration.nix` is upstream's module with identical options and
identical implementation; the only change is that it reads `pkgs.termux-am` and
`pkgs.termux-tools`. The `nix-on-droid` input reaches it through
`extraSpecialArgs` in `flake.nix`, which is what makes that `disabledModules`
path resolvable.

Note that `termux-tools` is a single derivation with eight outputs (`out`,
`setup_storage`, `open`, `open_url`, `reload_settings`, `wake_lock`,
`wake_unlock`, `xdg_open`), so one `prootUnpack` override covers every shim, and
the `.enable` flags only pick which outputs land in `environment.packages`.
Enabling `xdg-open` already compiled the other five; switching them on later
costs a symlink, not a build. `xdg_open` is itself a symlink to
`$open/bin/termux-open`, so the `open` output is in the closure regardless.

The cheap alternative I did not take was a five-line
`writeShellScriptBin "xdg-open"` calling `termux-am`. That gets the OAuth flow
and nothing else. The tradeoff for the full module is that it is a fork, and
forks drift — re-sync it when upstream changes the option set.

## Debugging the phone from the laptop

The app's terminal is the only way in, but it can be driven over USB without
touching the screen. `adb shell input text` types into the focused field, and two
file channels move data both ways:

```
adb push probe.sh /data/local/tmp/     # laptop -> phone: world-readable, app can read it
# in the app:  bash /android/data/local/tmp/probe.sh > /android/sdcard/out.txt 2>&1
adb shell cat /sdcard/out.txt          # phone -> laptop: /sdcard is app-writable
```

`/android` is the host Android root (nix-on-droid binds `-b /:/android`).
`/proc/<pid>/stat` is readable for the app's own processes, which is how a
"hang" gets classified: field 3 is the state, and comparing field 5 (`pgrp`)
against field 8 (`tpgid`) tells you whether a stopped process is merely in a
background process group. Note that wrapping a test in `timeout` creates a new
process group and manufactures exactly that false positive — use
`timeout --foreground`.
