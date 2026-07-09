# Tor net-gate

`net-gate` is an autostarting MicroVM that runs a **Tor transparent proxy**, isolating
anonymity-routed traffic in its own kernel and network namespace.

## Topology

- Host tap `vm-netgate` → `192.168.100.1/24`; guest → `192.168.100.2/24`.
- Resources: `cloud-hypervisor`, 512 MB RAM, 1 vCPU, vsock CID `10`.
- The guest mounts the host's SSH keys read-only over `virtiofs` (`/persist/etc/ssh → /etc/ssh`) so
  sops can decrypt inside the guest.

## Tor service

```nix
services.tor = {
  enable = true;
  client.enable = true;
  settings = {
    TransPort = [{ addr = "0.0.0.0"; port = 9040; }];
    SOCKSPort = [{ addr = "0.0.0.0"; port = 9050; }];
    DNSPort   = [{ addr = "0.0.0.0"; port = 5353; }];
    VirtualAddrNetworkIPv4 = "172.16.0.0/12";
    AutomapHostsOnResolve = true;
  };
};
```

The guest firewall opens TCP `9040` (TransPort) and `9050` (SOCKS5), plus UDP `5353` (DNSPort):

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 9040 9050 ];
  allowedUDPPorts = [ 5353 ];
};
```

## Per-app wrappers

[`home/scripts.nix`](https://github.com/lowcache/volnixos/blob/main/home/scripts.nix) installs
wrapper scripts that route individual applications through the guest's SOCKS5 proxy
(`192.168.100.2:9050`), each checking VM reachability first:

| Wrapper     | Behavior                                                                    |
| :---------- | :-------------------------------------------------------------------------- |
| `tor-brave` | Brave with `--proxy-server=socks5://…` and a dedicated `Brave-Browser-Tor` profile |
| `tor-curl`  | `curl --socks5-hostname …`                                                  |
| `tor-check` | Queries `check.torproject.org/api/ip` through the proxy                     |
| `anon-run`  | Runs a command as `anon-user` with `http(s)_proxy=socks5h://…` set          |

## Anonymous mode (`anonymous.target`)

For whole-process transparent routing, `nixos/configuration.nix` defines an on-demand
`anonymous.target` (armed/disarmed with the Fish abbreviations `anon-on` / `anon-off`):

- **UID isolation** — an `anon-user` (UID `10000`); an iptables *mangle* `OUTPUT` rule marks only
  that UID's packets with fwmark `0x1` (nftables is deliberately not used — it breaks Docker/libvirt
  networking on this host).
- **`anon-routing.service`** — policy-routes fwmark `0x1` via routing table `100`, whose default
  route is the net-gate guest (`192.168.100.2`). On-demand only (`partOf = anonymous.target`), so it
  never races the VM tap at boot.
- **`anon-socks-check.service`** — readiness gate: blocks until the guest's Tor SOCKS5
  (`192.168.100.2:9050`) actually answers, since the VM unit being active ≠ Tor bootstrapped.

## Usage

Ad-hoc: use the per-app wrappers above, or point any SOCKS5-capable client at
`192.168.100.2:9050`. Transparent: send TCP to `192.168.100.2:9040` and DNS to
`192.168.100.2:5353`. `AutomapHostsOnResolve` + `VirtualAddrNetworkIPv4` provide `.onion` name
resolution.

!!! note "WireGuard scaffold"
    `nixos/vms.nix` contains a commented `networking.wg-quick` block and a `wg_private_key` sops
    placeholder for chaining an upstream VPN ahead of Tor. It is inactive until a key is added to
    `nixos/vm-secrets.yaml`.

Start the runner directly with `make run-netgate` (`nix run .#net-gate`).
