{ config, pkgs, lib, inputs, ... }: {

  # Kernel & Performance
  boot = {
    kernelModules = [ "amdgpu" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_EnableGpuFirmware=1"
      #"nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "preempt=full"
      "threadirqs"
      "sysrq_always_enabled=1"
      # Ryzen CPU & Hybrid GPU Stability Parameters
      "amdgpu.dcdebugmask=0x10"
      "amdgpu.gpu_recovery=1"
      "processor.max_cstate=1"
      #"pcie_port_pm=off"
    ];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    kernel.sysctl = {
      # Memory Management
      "vm.max_map_count" = 2147483642;
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
      "vm.vfs_cache_pressure" = 50;
      # Panic Recovery
      "kernel.panic" = 10;
      "kernel.panic_on_oops" = 1;
      "kernel.sysrq" = 502;
      # Scheduling
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      # Network
      "net.core.netdev_max_backlog" = 16384;
      "net.core.somaxconn" = 8192;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  hardware.uinput.enable = true;
}
