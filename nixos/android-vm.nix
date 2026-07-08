{ pkgs, lib, config, inputs, ... }:
let
  # Android x86_64 system images with GApps support
  # We'll use the official Android emulator system images which include Play Store
  # For production-like testing, we use Google's official system images
  androidVersion = "35"; # Android 15 (API 35) - use "34" for Android 14, "33" for Android 13
  apiLevel = "android-${androidVersion}";
  abi = "x86_64";

  # Download and verify Android system image
  androidSysImg = pkgs.fetchzip {
    url = "https://dl.google.com/android/repository/sys-img/google_apis/${apiLevel}_${abi}.zip";
    # sha256 needs to be updated when Android version changes
    # Check https://developer.android.com/studio/releases/emulator for latest
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # placeholder - will fail, update after first fetch
  };

  # Magisk for reversible root
  magiskVersion = "28.1";
  magiskApk = pkgs.fetchurl {
    url = "https://github.com/topjohnwu/Magisk/releases/download/v${magiskVersion}/Magisk-v${magiskVersion}.apk";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # placeholder
  };

  # Pixel device fingerprint props for Play Integrity
  pixelProps = {
    "ro.product.brand" = "google";
    "ro.product.manufacturer" = "Google";
    "ro.product.model" = "Pixel 8 Pro";
    "ro.product.name" = "husky";
    "ro.product.device" = "husky";
    "ro.build.fingerprint" = "google/husky/husky:15/AP3A.240905.015.A2/12345678:user/release-keys";
    "ro.build.description" = "husky-user 15 AP3A.240905.015.A2 12345678 release-keys";
    "ro.bootimage.build.fingerprint" = "google/husky/husky:15/AP3A.240905.015.A2/12345678:user/release-keys";
    "ro.vendor.build.fingerprint" = "google/husky/husky:15/AP3A.240905.015.A2/12345678:user/release-keys";
    "ro.odm.build.fingerprint" = "google/husky/husky:15/AP3A.240905.015.A2/12345678:user/release-keys";
    "ro.system.build.fingerprint" = "google/husky/husky:15/AP3A.240905.015.A2/12345678:user/release-keys";
    "ro.system_ext.build.fingerprint" = "google/husky/husky:15/AP3A.240905.015.A2/12345678:user/release-keys";
    "ro.product.system.brand" = "google";
    "ro.product.system.manufacturer" = "Google";
    "ro.product.system.model" = "Pixel 8 Pro";
    "ro.product.system.name" = "husky";
    "ro.product.system.device" = "husky";
    "ro.product.vendor.brand" = "google";
    "ro.product.vendor.manufacturer" = "Google";
    "ro.product.vendor.model" = "Pixel 8 Pro";
    "ro.product.vendor.name" = "husky";
    "ro.product.vendor.device" = "husky";
    "ro.product.odm.brand" = "google";
    "ro.product.odm.manufacturer" = "Google";
    "ro.product.odm.model" = "Pixel 8 Pro";
    "ro.product.odm.name" = "husky";
    "ro.product.odm.device" = "husky";
    "ro.build.version.release" = "15";
    "ro.build.version.sdk" = "35";
    "ro.build.version.security_patch" = "2024-09-05";
    "ro.build.version.codenames" = "REL";
    "ro.build.version.all_codenames" = "REL";
    "ro.build.version.incremental" = "12345678";
    "ro.build.type" = "user";
    "ro.build.tags" = "release-keys";
    "ro.build.flavor" = "husky-user";
    "ro.build.product" = "husky";
    "ro.boot.product.hardware.sku" = "";
    "ro.boot.hardware.sku" = "";
    "ro.boot.hardware" = "husky";
    "ro.hardware" = "husky";
    "ro.board.platform" = "gs101";
    "ro.boot.prerelease" = "false";
    "ro.build.characteristics" = "nosdcard";
  };

in
{
  # Enable libvirt/QEMU (already enabled in windows-vm.nix, but ensure)
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
    };
  };

  # Android VM specific packages
  environment.systemPackages = with pkgs; [
    qemu_kvm
    libvirt
    virt-manager
    virt-viewer
    swtpm
    android-tools
    adb
    fastboot
    scrcpy # for display mirroring
    virglrenderer # for GPU acceleration
    mesa # for virgl
    glslang # for vulkan
    spice-gtk # for SPICE display
    usbredir # for USB redirect
  ];

  # SPICE USB redirection for ADB over USB
  virtualisation.spiceUSBRedirection.enable = true;

  # User permissions for libvirt/KVM
  users.users.lowcache.extraGroups = [ "libvirtd" "kvm" "render" "video" ];

  # Store Android VM images on the dedicated Storage NVMe (bind-mounted via windows-vm.nix)
  systemd.tmpfiles.rules = [
    "d /home/lowcache/Storage/android-vm 0755 lowcache users -"
    "d /home/lowcache/Storage/android-vm/images 0755 lowcache users -"
    "d /home/lowcache/Storage/android-vm/shared 0755 lowcache users -"
  ];

  # Bind mount the Storage/android-vm to /var/lib/libvirt/images/android-vm
  # This keeps VM disks off the system drive and on the dedicated NVMe
  fileSystems."/var/lib/libvirt/images/android-vm" = {
    device = "/home/lowcache/Storage/android-vm";
    fsType = "none";
    options = [ "bind" "x-systemd.requires-mounts-for=/home/lowcache/Storage" "nofail" ];
  };

  # Network for Android VM - isolated NAT with port forwarding for ADB
  systemd.network.networks."20-android-vm" = {
    matchConfig.Name = "virbr-android";
    networkConfig = {
      Address = [ "192.168.102.1/24" ];
      DHCPServer = {
        PoolOffset = "100";
        PoolSize = "50";
      };
      IPForward = true;
      IPMasquerade = true;
    };
  };

  # NetworkManager ignores this bridge
  networking.networkmanager.unmanaged = [
    "interface-name:virbr-android"
    "interface-name:vnet-android"
  ];

  # Android VM definition via libvirt XML (generated via nixos module)
  # We use a systemd service to define and manage the VM
  systemd.services.android-vm-define = {
    description = "Define Android VM in libvirt";
    after = [ "libvirtd.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.libvirt}/bin/virsh define /etc/libvirt/qemu/android-vm.xml";
      ExecStop = "${pkgs.libvirt}/bin/virsh undefine android-vm --nvram";
    };
  };

  # The libvirt XML for the Android VM
  environment.etc."libvirt/qemu/android-vm.xml".text =
    let
      vmName = "android-vm";
      cpuCount = 4;
      memoryMiB = 8192; # 8GB RAM
      diskSize = "64G";
      # Use the system image we fetched
      systemImg = androidSysImg;
    in
    ''
      <domain type='kvm'>
        <name>${vmName}</name>
        <uuid>${lib.genUUID vmName}</uuid>
        <metadata>
          <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libosinfo/1.0">
            <libosinfo:os id="org.android.android15"/>
          </libosinfo:libosinfo>
        </metadata>
        <memory unit='MiB'>${memoryMiB}</memory>
        <currentMemory unit='MiB'>${memoryMiB}</currentMemory>
        <vcpu placement='static'>${cpuCount}</vcpu>
        <os>
          <type arch='x86_64' machine='pc-q35-9.0'>hvm</type>
          <loader readonly='yes' type='pflash'>${pkgs.OVMF.fd}/OVMF_CODE.fd</loader>
          <nvram template='/usr/share/OVMF/OVMF_VARS.fd'>/var/lib/libvirt/qemu/nvram/${vmName}_VARS.fd</nvram>
          <boot dev='hd'/>
          <bootmenu enable='yes' timeout='5000'/>
        </os>
        <features>
          <acpi/>
          <apic/>
          <hyperv>
            <relaxed state='on'/>
            <vapic state='on'/>
            <spinlocks state='on' retries='8191'/>
            <vpindex state='on'/>
            <synic state='on'/>
            <stimer state='on'/>
            <reset state='on'/>
            <frequencies state='on'/>
            <reenlightenment state='on'/>
            <tlbflush state='on'/>
            <ipi state='on'/>
          </hyperv>
          <kvm>
            <hidden state='on'/>
          </kvm>
          <vmport state='off'/>
          <ioapic driver='kvm'/>
          <smm state='on'/>
        </features>
        <cpu mode='host-passthrough' check='none' migratable='on'>
          <topology sockets='1' dies='1' cores='${cpuCount}' threads='1'/>
          <feature policy='require' name='invtsc'/>
          <feature policy='require' name='vmx'/>
          <feature policy='require' name='ept'/>
          <feature policy='require' name='spec-ctrl'/>
          <feature policy='require' name='ssbd'/>
          <feature policy='require' name='pdpe1gb'/>
          <feature policy='require' name='pku'/>
          <feature policy='require' name='ospke'/>
          <feature policy='require' name='vaes'/>
          <feature policy='require' name='vpclmulqdq'/>
          <feature policy='require' name='gfni'/>
          <feature policy='require' name='avx512-vbmi'/>
          <feature policy='require' name='avx512-bitalg'/>
          <feature policy='require' name='avx512-vpopcntdq'/>
          <feature policy='require' name='avx512-vnni'/>
          <feature policy='require' name='avx512-bf16'/>
          <feature policy='require' name='avx512-fp16'/>
          <feature policy='require' name='amd-ssbd'/>
          <feature policy='require' name='virt-ssbd'/>
        </cpu>
        <clock offset='utc'>
          <timer name='rtc' tickpolicy='catchup'/>
          <timer name='pit' tickpolicy='delay'/>
          <timer name='hpet' present='no'/>
          <timer name='hypervclock' present='yes'/>
          <timer name='tsc' present='yes' mode='native'/>
        </clock>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <pm>
          <suspend-to-mem enabled='no'/>
          <suspend-to-disk enabled='no'/>
        </pm>
        <devices>
          <emulator>${pkgs.qemu_kvm}/bin/qemu-system-x86_64</emulator>
          <!-- System disk (Android system image) -->
          <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2' discard='unmap' cache='unsafe' io='native'/>
            <source file='/var/lib/libvirt/images/android-vm/images/system.qcow2'/>
            <target dev='vda' bus='virtio'/>
            <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
          </disk>
          <!-- Data disk (user data partition) -->
          <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2' discard='unmap' cache='unsafe' io='native'/>
            <source file='/var/lib/libvirt/images/android-vm/images/userdata.qcow2'/>
            <target dev='vdb' bus='virtio'/>
            <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
          </disk>
          <!-- Cache disk -->
          <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2' discard='unmap' cache='unsafe' io='native'/>
            <source file='/var/lib/libvirt/images/android-vm/images/cache.qcow2'/>
            <target dev='vdc' bus='virtio'/>
            <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
          </disk>
          <!-- Shared folder for host<->guest file transfer -->
          <filesystem type='mount' accessmode='passthrough'>
            <driver type='virtiofs'/>
            <source dir='/home/lowcache/Storage/android-vm/shared'/>
            <target dir='host_shared'/>
            <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
          </filesystem>
          <!-- GPU: virtio-gpu with virgl 3D acceleration -->
          <video>
            <model type='virtio' heads='1' primary='yes'>
              <acceleration accel3d='yes'/>
              <virgl/>
            </model>
            <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
          </video>
          <!-- Display: SPICE with OpenGL -->
          <graphics type='spice' autoport='yes' listen='none'>
            <listen type='none'/>
            <image compression='off'/>
            <gl enable='yes' rendernode='/dev/dri/renderD128'/>
          </graphics>
          <audio id='1' type='spice'/>
          <!-- Input -->
          <input type='tablet' bus='virtio'/>
          <input type='mouse' bus='virtio'/>
          <input type='keyboard' bus='virtio'/>
          <!-- Network: virtio-net with vhost -->
          <interface type='network'>
            <mac address='52:54:00:12:34:56'/>
            <source network='android-vm-net'/>
            <model type='virtio'/>
            <driver name='vhost' queues='4'/>
            <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
          </interface>
          <!-- Serial console for debugging -->
          <console type='pty'>
            <target type='virtio' port='0'/>
          </console>
          <channel type='spicevmc'>
            <target type='virtio' name='com.redhat.spice.0'/>
            <address type='virtio-serial' controller='0' bus='0' port='1'/>
          </channel>
          <!-- VirtIO RNG -->
          <rng model='virtio'>
            <backend model='random'>/dev/urandom</backend>
            <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
          </rng>
          <!-- Memory balloon -->
          <memballoon model='virtio'>
            <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
          </memballoon>
          <!-- TPM for Android Keystore/StrongBox emulation -->
          <tpm model='tpm-tis'>
            <backend type='emulator' version='2.0'>
              <backendPath>${pkgs.swptm}/bin/swtpm</backendPath>
            </backend>
          </tpm>
          <!-- VirtIO SCSI controller for better disk performance -->
          <controller type='scsi' index='0' model='virtio-scsi'>
            <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
          </controller>
          <!-- USB controller for ADB passthrough -->
          <controller type='usb' index='0' model='qemu-xhci' ports='15'>
            <address type='pci' domain='0x0000' bus='0x09' slot='0x00' function='0x0'/>
          </controller>
          <!-- USB redirect for ADB over SPICE -->
          <redirdev bus='usb' type='spicevmc'>
            <address type='pci' domain='0x0000' bus='0x0a' slot='0x00' function='0x0'/>
          </redirdev>
          <redirdev bus='usb' type='spicevmc'>
            <address type='pci' domain='0x0000' bus='0x0b' slot='0x00' function='0x0'/>
          </redirdev>
        </devices>
        <qemu:commandline>
          <qemu:arg value='-kernel'/>
          <qemu:arg value='${systemImg}/kernel-ranchu'/>
          <qemu:arg value='-append'/>
          <qemu:arg value='console=ttyS0 androidboot.hardware=ranchu androidboot.boot_devices=pci.0000:04.00.0 androidboot.verifiedbootstate=green init=/init ro root=/dev/vda1 ro.build.fingerprint=${pixelProps."ro.build.fingerprint"} androidboot.verifiedbootstate=green'/>
          <qemu:arg value='-initrd'/>
          <qemu:arg value='${systemImg}/ramdisk.img'/>
          <!-- Pixel device properties via qemu command line -->
          ${lib.concatMapStringsSep " " (k: v: "-qemu:arg value=-prop -qemu:arg value=${k}=${v}") (builtins.attrNames pixelProps)}
        </qemu:commandline>
      </domain>
    '';

  # Network definition for the Android VM
  environment.etc."libvirt/qemu/networks/android-vm-net.xml".text = ''
    <network>
      <name>android-vm-net</name>
      <uuid>${lib.genUUID "android-vm-net"}</uuid>
      <forward mode='nat'>
        <nat>
          <port start='1024' end='65535'/>
        </nat>
      </forward>
      <bridge name='virbr-android' stp='on' delay='0'/>
      <mac address='52:54:00:aa:bb:cc'/>
      <ip address='192.168.102.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.102.100' end='192.168.102.150'/>
        </dhcp>
      </ip>
    </network>
  '';

  # Helper scripts for Android VM management
  environment.systemPackages = with pkgs; [
    (writeScriptBin "android-vm-setup" ''
      #!/bin/sh
      set -eu
      IMG_DIR="/home/lowcache/Storage/android-vm/images"
      mkdir -p "$IMG_DIR"

      # Create qcow2 disks if they don't exist
      for disk in system userdata cache; do
        if [ ! -f "$IMG_DIR/$disk.qcow2" ]; then
          echo "Creating $disk.qcow2..."
          case $disk in
            system) SIZE="16G" ;;
            userdata) SIZE="32G" ;;
            cache) SIZE="4G" ;;
          esac
          qemu-img create -f qcow2 "$IMG_DIR/$disk.qcow2" "$SIZE"
        fi
      done

      # Extract system image to system.qcow2 (first run only)
      if [ ! -f "$IMG_DIR/system.qcow2.extracted" ]; then
        echo "Extracting Android system image..."
        # The system image is in the fetched zip, extract system.img
        unzip -o "${androidSysImg}/system.img" -d "$IMG_DIR/" 2>/dev/null || true
        # Convert raw to qcow2
        qemu-img convert -f raw -O qcow2 "$IMG_DIR/system.img" "$IMG_DIR/system.qcow2"
        touch "$IMG_DIR/system.qcow2.extracted"
      fi

      # Define and start the network
      virsh net-define /etc/libvirt/qemu/networks/android-vm-net.xml
      virsh net-autostart android-vm-net
      virsh net-start android-vm-net

      # Define the VM
      virsh define /etc/libvirt/qemu/android-vm.xml

      echo "Android VM setup complete. Start with: virsh start android-vm"
      echo "Connect with: virt-viewer --connect qemu:///system android-vm"
      echo "ADB will be available at: adb connect 192.168.102.100:5555 (after enabling in VM)"
    ''
    ),

    (writeScriptBin "android-vm-install-magisk" ''
      #!/bin/sh
      # Install Magisk for reversible root
      set -eu
      ADB="adb"
      MAGISK_APK="${magiskApk}"

      echo "Installing Magisk..."
      $ADB install -r "$MAGISK_APK"
      echo "Magisk app installed. Open it in the VM and patch the boot image."
      echo "Then run: android-vm-patch-boot"
    ''
    ),

    (writeScriptBin "android-vm-patch-boot" ''
      #!/bin/sh
      # Patch boot image with Magisk (run after Magisk app patches it in VM)
      set -eu
      ADB="adb"
      IMG_DIR="/home/lowcache/Storage/android-vm/images"

      echo "Pulling patched boot image from VM..."
      $ADB pull /sdcard/Download/magisk_patched-*.img "$IMG_DIR/boot_patched.img"
      echo "Patched boot image saved to $IMG_DIR/boot_patched.img"
      echo "Reboot VM and flash with: fastboot flash boot $IMG_DIR/boot_patched.img"
    ''
    ),

    (writeScriptBin "android-vm-unroot" ''
      #!/bin/sh
      # Unroot / hide root for banking apps
      set -eu
      ADB="adb"

      echo "Uninstalling Magisk (unroot)..."
      $ADB shell su -c "magisk --uninstall" 2>/dev/null || true
      $ADB uninstall com.topjohnwu.magisk 2>/dev/null || true

      echo "Root removed. Reboot VM for changes to take effect."
      echo "Verify with: adb shell su -c 'id' (should fail)"
    ''
    ),

    (writeScriptBin "android-vm-hide-root" ''
      #!/bin/sh
      # Hide root using Magisk's Zygisk + DenyList for banking apps
      set -eu
      ADB="adb"

      echo "Enabling Zygisk and configuring DenyList for banking apps..."
      $ADB shell su -c "
        magisk --enable-zygisk
        magisk --denylist-add com.google.android.apps.wallet
        magisk --denylist-add com.android.chrome
        magisk --denylist-add com.google.android.gms
        magisk --denylist-add com.google.android.play.games
        # Add your banking package names here
      "

      echo "Root hidden for configured apps. Enable 'Enforce DenyList' in Magisk app."
      echo "Also enable 'Hide Magisk app' and rename package in Magisk settings."
    ''
    ),

    (writeScriptBin "android-vm-reset-fingerprint" ''
      #!/bin/sh
      # Reset device fingerprint to Pixel 8 Pro (for Play Integrity)
      set -eu
      ADB="adb"

      echo "Setting Pixel 8 Pro fingerprint..."
      ${lib.concatMapStringsSep " " (k: v: "
        $ADB shell \"setprop ${k} ${v}\"
      ") (builtins.attrNames pixelProps)}

      echo "Fingerprint props set. Reboot VM to persist."
      echo "Note: These are runtime props. For persistent props, modify /system/build.prop (requires root)."
    ''
    ),

    (writeScriptBin "android-vm-play-integrity-check" ''
      #!/bin/sh
      # Check Play Integrity API status
      set -eu
      ADB="adb"

      echo "Checking Play Integrity status..."
      $ADB shell dumpsys package com.google.android.gms | grep -A5 "Play Integrity"
      echo ""
      echo "Install 'Play Integrity API Checker' from Play Store for detailed report."
      echo "Or run: adb shell am start -n com.google.android.gms/.playintegrity.PlayIntegrityTestActivity"
    ''
    ),

    (writeScriptBin "android-vm-start" ''
      #!/bin/sh
      virsh start android-vm
      sleep 3
      virt-viewer --connect qemu:///system android-vm
    ''
    ),

    (writeScriptBin "android-vm-stop" ''
      #!/bin/sh
      virsh shutdown android-vm
    ''
    ),

    (writeScriptBin "android-vm-snapshot-save" ''
      #!/bin/sh
      # Save VM snapshot (requires root for consistent state)
      SNAP_NAME="android-vm-$(date +%Y%m%d-%H%M%S)"
      virsh snapshot-create-as android-vm "$SNAP_NAME" --description "Android VM snapshot" --atomic
      echo "Snapshot saved: $SNAP_NAME"
    ''
    ),

    (writeScriptBin "android-vm-snapshot-restore" ''
      #!/bin/sh
      if [ -z "${1:-}" ]; then
        echo "Usage: android-vm-snapshot-restore <snapshot-name>"
        virsh snapshot-list android-vm
        exit 1
      fi
      virsh snapshot-revert android-vm "$1"
      echo "Restored snapshot: $1"
    ''
    ),
  ];

  # ADB connection helper - auto-connect to VM
  systemd.user.services.adb-android-vm = {
    description = "Auto-connect ADB to Android VM";
    after = [ "network-online.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.android-tools}/bin/adb connect 192.168.102.100:5555";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

  # Documentation
  environment.etc."android-vm/README.md".text = ''
    # Android VM for Production Testing

    ## Quick Start

    1. **Initial Setup** (run once):
       ```bash
       android-vm-setup
       ```

    2. **Start VM**:
       ```bash
       android-vm-start
       ```

    3. **Inside VM Setup**:
       - Complete Android setup wizard
       - Enable Developer Options: Settings > About Phone > Build Number (tap 7x)
       - Enable USB Debugging: Settings > Developer Options > USB Debugging
       - Enable Wireless Debugging: Settings > Developer Options > Wireless Debugging
       - Note the IP/port shown (e.g., 192.168.102.100:5555)

    4. **Connect ADB**:
       ```bash
       adb connect 192.168.102.100:5555
       ```

    ## Root Management (Reversible)

    **Install Magisk (Root):**
    ```bash
    android-vm-install-magisk
    # Then in VM: Open Magisk app > Install > Direct Install (Recommended)
    # After reboot: android-vm-patch-boot
    ```

    **Hide Root for Banking Apps:**
    ```bash
    android-vm-hide-root
    # In Magisk app: Enable Zygisk, Enable Enforce DenyList
    # Add banking apps to DenyList
    # Hide Magisk app (rename package)
    ```

    **Unroot Completely:**
    ```bash
    android-vm-unroot
    ```

    ## Pixel Fingerprint (Play Integrity)

    Set Pixel 8 Pro fingerprint:
    ```bash
    android-vm-reset-fingerprint
    ```

    Check Play Integrity status:
    ```bash
    android-vm-play-integrity-check
    ```

    ## Snapshots (for testing different states)

    Save clean state:
    ```bash
    android-vm-snapshot-save
    ```

    Restore:
    ```bash
    android-vm-snapshot-restore <snapshot-name>
    ```

    ## Banking App Testing Workflow

    1. Start with clean snapshot (unrooted, Pixel fingerprint)
    2. Install banking app from Play Store
    3. Test app functionality
    4. If root needed for testing: install Magisk, test, then unroot/hide
    5. Restore clean snapshot for production testing

    ## GPU Acceleration

    - Uses virtio-gpu with virgl 3D acceleration
    - Requires host GPU drivers (AMD/NVIDIA) with render node access
    - SPICE display with OpenGL rendering
    - For NVIDIA: ensure nvidia-vaapi-driver and libva are installed

    ## Storage

    All VM disks stored on `/home/lowcache/Storage/android-vm/images/` (dedicated NVMe)
    Shared folder: `/home/lowcache/Storage/android-vm/shared/` (mounted at /mnt/host_shared in VM)

    ## Troubleshooting

    - **ADB not connecting**: Check VM IP with `virsh domifaddr android-vm`, ensure wireless debugging enabled
    - **Play Integrity fails**: Ensure Pixel fingerprint set, Magisk hidden/denylist configured, Play Services updated
    - **GPU issues**: Check `virglrenderer` and `mesa` installed, SPICE GL enabled
    - **Performance**: Increase CPU/RAM in XML, use virtio-scsi for disks
  '';
}
