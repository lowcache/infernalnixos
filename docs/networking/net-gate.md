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
    DNSPort   = [{ addr = "0.0.0.0"; port = 5353; }];
    VirtualAddrNetworkIPv4 = "172.16.0.0/12";
    AutomapHostsOnResolve = true;
  };
};
```

The guest firewall opens only TCP `9040` (TransPort) and UDP `5353` (DNSPort):

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 9040 ];
  allowedUDPPorts = [ 5353 ];
};
```

## Usage

To route a client through Tor, send its TCP traffic to `192.168.100.2:9040` and its DNS to
`192.168.100.2:5353` (for example via host firewall/redirect rules or per-application proxy
settings). `AutomapHostsOnResolve` + `VirtualAddrNetworkIPv4` provide `.onion` name resolution.

!!! note "WireGuard scaffold"
    `nixos/vms.nix` contains a commented `networking.wg-quick` block and a `wg_private_key` sops
    placeholder for chaining an upstream VPN ahead of Tor. It is inactive until a key is added to the
    guest's `secrets.yaml`.

Start the runner directly with `make run-netgate` (`nix run .#net-gate`).
