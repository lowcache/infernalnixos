<div align="center">

<img alt="Vol[atile] NixOS banner" src="./assets/ms6pkfms6pkfms6p.png" width="100%">

<p>
  <img alt="NixOS unstable" src="https://img.shields.io/badge/NixOS-unstable-5277C3?style=for-the-badge&logo=nixos&logoColor=white">
  <img alt="Lix" src="https://img.shields.io/badge/Nix_daemon-Lix-3a3a3a?style=for-the-badge&logo=nixos&logoColor=88c0d0">
  <img alt="niri" src="https://img.shields.io/badge/WM-niri-7E9CD8?style=for-the-badge&logoColor=white">
  <img alt="Wayland" src="https://img.shields.io/badge/Display-Wayland-FFB300?style=for-the-badge&logo=wayland&logoColor=white">
</p>
<p>
  <a href="https://volnixos-wiki.pgs.sh/"><img alt="Documentation" src="https://img.shields.io/badge/📖_full_docs-volnixos--wiki.pgs.sh-3e9e40?style=flat-square"></a>
  <a href="https://github.com/lowcache/volnixos/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/lowcache/volnixos?style=flat-square&logo=git&logoColor=white&label=last%20commit&color=5277C3"></a>
</p>

### Vol(atile) NixOS — a stateless, flake-driven NixOS workstation

</div>

A declarative, performance-tuned, **ephemeral** NixOS configuration built on Nix Flakes and the
[Lix](https://lix.systems) daemon. The root filesystem is a `tmpfs` wiped on every boot; all durable
state is mapped onto `/persist` via [`impermanence`](https://github.com/nix-community/impermanence). It
adds a CachyOS low-latency kernel, UEFI Secure Boot (Lanzaboote), `sops-nix` secrets, isolated
`microvm.nix` gateways, CUDA-accelerated local AI, and a niri + Noctalia v5 Wayland desktop.

## 📖 Documentation

**Full documentation lives at → [volnixos-wiki.pgs.sh](https://volnixos-wiki.pgs.sh/)**

| Topic | |
| :--- | :--- |
| [Architecture](https://volnixos-wiki.pgs.sh/architecture/) | Boot, impermanence, kernel, secrets |
| [Networking](https://volnixos-wiki.pgs.sh/networking/) | Tor `net-gate` & Tailscale MicroVMs |
| [Desktop](https://volnixos-wiki.pgs.sh/desktop/) | niri, Noctalia, theming engine |
| [Reference](https://volnixos-wiki.pgs.sh/reference/flake/) | Flake, Home Manager modules, dotfiles |
| [Tooling](https://volnixos-wiki.pgs.sh/tooling/makefile/) | Makefile, Fish, agent toolchain |
| [Limbo profile](https://volnixos-wiki.pgs.sh/limbo/) | Portable, generic-hardware install |

The docs source is in [`docs/`](docs/) (MkDocs Material). Preview locally with `make docs-serve`.

## Quick start

```bash
git clone https://github.com/lowcache/volnixos.git ~/.nix-config
cd ~/.nix-config
make check          # nix flake check
make build          # build without switching
sudo make switch    # rebuild + switch (HOST=volnix)
```

> [!WARNING]
> The `volnix` host targets specific hardware (AMD Ryzen + hybrid AMD/NVIDIA GPU, ASUS laptop) and is
> published as a **reference**, not a turnkey install. For a clean build on standard x86_64 hardware,
> use the [`limbo`](https://volnixos-wiki.pgs.sh/limbo/) profile.

## Layout

```text
.nix-config/
├── flake.nix          # inputs, overlays, hosts (volnix, limbo), VM runners
├── Makefile           # canonical operations interface (make help)
├── nixos/             # system modules + nixos/limbo (generic host)
├── home/              # Home Manager modules
├── dots/              # dotfiles (out-of-store symlinked to ~/.config)
├── scripts/           # agent toolchain (memd, tether, agent-scaffold)
├── docs/              # MkDocs Material documentation source
└── assets/            # banner / branding
```
