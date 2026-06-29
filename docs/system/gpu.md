# Hybrid GPU

`volnix` is an ASUS laptop with a **hybrid dual-GPU** configuration: an AMD HawkPoint2 iGPU and an
NVIDIA RTX 4050 Mobile dGPU. Both drivers are loaded, and the niri session renders on the iGPU by
default for battery efficiency.

## Driver setup

```nix
boot.kernelModules = [ "amdgpu" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];
```

The NVIDIA-specific environment offload variables in
[`home/default.nix`](https://github.com/lowcache/volnixos/blob/main/home/default.nix)
(`__NV_PRIME_RENDER_OFFLOAD`, `GBM_BACKEND`, `__GLX_VENDOR_LIBRARY_NAME`, …) are **commented out** so
the compositor stays on the AMD iGPU. Per-command offload is available through the `nvrun` alias:

```fish
nvrun glxinfo        # __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia glxinfo
```

## Power management

The dGPU is kept idle and allowed to reach **RTD3 (0 W) suspend** whenever possible. The Ollama daemon
unloads models after `OLLAMA_KEEP_ALIVE=5m`, releasing CUDA handles so the card can power down (see
[AI Stack](ai-stack.md)).

!!! note "ASUS services"
    `services.asusd` is enabled for ASUS hardware control. `services.supergfxd` and
    `services.power-profiles-daemon` are disabled.

## Stability workarounds

| Symptom                                     | Mitigation                                              |
| :------------------------------------------ | :----------------------------------------------------- |
| AMD display-core glitches                   | `amdgpu.dcdebugmask=0x10` ([kernel params](../architecture/kernel.md)) |
| Ryzen + hybrid-GPU C-state instability      | `processor.max_cstate=1`                                |
| Krita Qt6 canvas freeze on Wayland (Hyprland) | Unconditional native Wayland under niri resolves this. No xcb wrapper needed. ([Troubleshooting](../troubleshooting.md)) |

## Containers & libraries

- Docker exposes the dGPU to containers via `--device nvidia.com/gpu=0` (see the Fooocus container in
  [AI Stack](ai-stack.md)).
- `programs.nix-ld` ships CUDA, Vulkan, VA-API, and OpenGL libraries so unpatched binaries and
  AppImages find GPU userspace at runtime.
- Diagnostics installed: `nvtopPackages.nvidia`, `vulkan-tools`, `libva-utils`, `clinfo`,
  `nvidia-vaapi-driver`.
