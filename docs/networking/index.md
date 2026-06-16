# 🌐 Networking & MicroVMs

Two isolated guests are declared in
[`nixos/vms.nix`](https://github.com/lowcache/volnixos/blob/main/nixos/vms.nix) using
[`microvm.nix`](https://github.com/astro/microvm.nix) with the `cloud-hypervisor` backend. Each guest
gets a static-IP tap interface; the host side is driven by `systemd-networkd`, and NetworkManager is
told to leave the taps alone.

```mermaid
graph LR
    subgraph Host["volnix host · systemd-networkd"]
        H1["vm-netgate<br/>192.168.100.1/24"]
        H2["vm-tailscale<br/>192.168.101.1/24"]
    end
    subgraph NG["net-gate · autostart"]
        T["Tor transparent proxy<br/>TransPort 9040 · DNSPort 5353"]
    end
    subgraph TSVM["tailscale · manual"]
        TS["tailscaled<br/>IP forwarding"]
    end
    H1 <-->|"guest .100.2"| NG
    H2 <-->|"guest .101.2"| TSVM
```

## Guests

| Guest       | Hypervisor       | Resources       | Host ↔ Guest                      | Autostart | Page                        |
| :---------- | :--------------- | :-------------- | :-------------------------------- | :-------- | :-------------------------- |
| `net-gate`  | cloud-hypervisor | 512 MB / 1 vCPU | `192.168.100.1` ↔ `192.168.100.2` | yes       | [Tor net-gate](net-gate.md) |
| `tailscale` | cloud-hypervisor | 256 MB / 1 vCPU | `192.168.101.1` ↔ `192.168.101.2` | no        | [Tailscale VM](tailscale.md)|

## Host-side isolation

```nix
# NetworkManager must not touch the VM taps
networking.networkmanager.unmanaged = [
  "interface-name:vm-netgate"
  "interface-name:vm-tailscale"
];
```

The host `systemd-networkd` networks (`10-microvm-tap`, `11-tailscale-tap`) assign the gateway
addresses, enable `IPv4Forwarding`, and set `RequiredForOnline = "no"` so the taps never become the
host's default route. Static IPs are deliberate: DHCP would shift addresses on VM restart and break
the forwarding configuration.

## Runners

The guests are also exposed as flake packages:

```bash
make run-netgate     # nix run .#net-gate
make run-tailscale   # nix run .#tailscale-vm
```

!!! info "Fast shutdown"
    Host-side overrides set `TimeoutStopSec` on the `microvm@*` and `microvm-virtiofsd@*` units
    (and force `Type = simple` on virtiofsd) so the guests tear down quickly at poweroff.
