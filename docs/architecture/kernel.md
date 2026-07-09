# Kernel & Performance

The system runs the **CachyOS** kernel with low-latency tuning, set in
[`nixos/hardware/asus-ryzen-nvidia/kernel.nix`](https://github.com/lowcache/volnixos/blob/main/nixos/hardware/asus-ryzen-nvidia/kernel.nix)
via the `nix-cachyos-kernel` overlay (applied in `flake.nix`):

```nix
boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
```

## Kernel parameters

| Parameter                          | Purpose                                            |
| :--------------------------------- | :------------------------------------------------- |
| `preempt=full`                     | Full preemption for interactivity under load       |
| `threadirqs`                       | Threaded IRQ handling                               |
| `processor.max_cstate=1`           | Limit CPU C-states (Ryzen hybrid-GPU stability)     |
| `nvidia-drm.modeset=1`             | NVIDIA DRM modesetting                              |
| `nvidia.NVreg_EnableGpuFirmware=1` | Enable GSP firmware                                 |
| `amdgpu.dcdebugmask=0x10`          | AMD display-core stability workaround               |
| `amdgpu.gpu_recovery=1`            | Enable AMD GPU recovery                             |
| `sysrq_always_enabled=1`           | Magic SysRq available                               |

## Sysctl tuning

`boot.kernel.sysctl` (also in `kernel.nix`) sets memory, scheduling, and network parameters:

=== "Memory"

    ```nix
    "vm.max_map_count" = 2147483642;   # very high mmap limit (large apps / games)
    "vm.swappiness" = 180;             # aggressive swap (paired with zramSwap below)
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    ```

=== "Network"

    ```nix
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    ```

=== "Recovery & scheduling"

    ```nix
    "kernel.panic" = 10;               # reboot 10s after panic
    "kernel.panic_on_oops" = 1;
    "kernel.sysrq" = 502;
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    ```

## Swap

`nixos/hardware-configuration.nix` pairs the aggressive swappiness with a compressed-RAM tier and a
physical fallback: `zramSwap` (`zstd`, up to 50% of RAM) plus a 16 GB swapfile at `/persist/swapfile`.

## Service-manager timeouts

To keep shutdown fast (a recurring pain point with FUSE mounts and stubborn units),
`systemd.settings.Manager` sets `DefaultTimeoutStopSec = "10s"` (5s for the user manager), and a
`decapitate-fuse-mounts` oneshot force-unmounts the xdg-document-portal FUSE at shutdown to release
`/nix`.

!!! note "Schedulers"
    `services.scx` (sched-ext, e.g. `scx_bpfland`) is wired in but currently disabled
    (`enable = false`); the CachyOS kernel's default scheduler is in use.
