---
hide:
  - navigation
  - toc
---

<div class="vol-hero" markdown>

<img class="vol-banner" src="assets/banner.png" alt="Vol[atile] NixOS">

<div class="vol-badges" markdown>
![NixOS unstable](https://img.shields.io/badge/NixOS-unstable-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Lix](https://img.shields.io/badge/Nix_daemon-Lix-3a3a3a?style=for-the-badge&logo=nixos&logoColor=88c0d0)
![niri](https://img.shields.io/badge/WM-niri-7E9CD8?style=for-the-badge&logoColor=white)
![Wayland](https://img.shields.io/badge/Display-Wayland-FFB300?style=for-the-badge&logo=wayland&logoColor=white)
</div>

<p class="vol-tagline">STATELESS CONFIGURATION · TMPFS ROOT · DEV LOWCACHE</p>

</div>

# Vol[atile] NixOS

A declarative, performance-tuned, **ephemeral** NixOS workstation built on Nix Flakes and the
[Lix](https://lix.systems) daemon. The root filesystem is a `tmpfs` wiped on every boot; all durable
state is mapped onto `/persist` through
[`impermanence`](https://github.com/nix-community/impermanence). On top sits a CachyOS low-latency
kernel, UEFI Secure Boot via Lanzaboote, `sops-nix` encrypted secrets, isolated `microvm.nix` network
gateways, CUDA-accelerated local AI, and a niri + Noctalia v5 Wayland desktop.

<div class="vol-grid" markdown>

<div class="vol-card" markdown>
### 🧬 Ephemeral Root
`tmpfs` root rebuilt clean each boot; durable state and live dotfiles mapped from `/persist`.
[Read more →](architecture/impermanence.md)
</div>

<div class="vol-card" markdown>
### 🔐 Secure Boot + Secrets
Lanzaboote UEFI Secure Boot and `sops-nix` + age encrypted secrets.
[Read more →](architecture/secrets.md)
</div>

<div class="vol-card" markdown>
### 🌐 MicroVM Gateways
Isolated `cloud-hypervisor` guests: a Tor transparent proxy and a Tailscale router.
[Read more →](networking/index.md)
</div>

<div class="vol-card" markdown>
### 🎨 Noctalia Desktop
niri compositor with the Noctalia v5 native Wayland shell and a JSON theme engine.
[Read more →](desktop/index.md)
</div>

<div class="vol-card" markdown>
### 🤖 Local AI Stack
CUDA Ollama + Open WebUI, GPU-passthrough Fooocus, and a custom agent toolchain.
[Read more →](system/ai-stack.md)
</div>

<div class="vol-card" markdown>
### 📖 Portfolio, Not a Distro
A personal, hardware-specific config published as proof-of-work — read it and borrow patterns; it is not a turnkey install.
[Read more →](architecture/index.md)
</div>

</div>

---

## Quick start

```bash
# Clone
git clone https://github.com/lowcache/volnixos.git ~/.nix-config
cd ~/.nix-config

# Validate, then build/switch via the canonical Makefile interface
make check          # nix flake check
make build          # build without switching
sudo make switch    # rebuild + switch the live system (HOST=volnix)
```

!!! note "A portfolio, not a distro"
    The `volnix` host targets a specific machine (AMD Ryzen + hybrid AMD iGPU / NVIDIA RTX 4050,
    ASUS laptop) and is published as **proof-of-work** — meant to be read and borrowed from, not
    installed wholesale.

[Architecture overview](architecture/index.md){ .md-button .md-button--primary }
[Browse the source](https://github.com/lowcache/volnixos){ .md-button }
