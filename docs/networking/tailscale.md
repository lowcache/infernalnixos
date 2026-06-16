# Tailscale VM

`tailscale` is a manually-started MicroVM that runs `tailscaled` with routing features enabled,
keeping the mesh-VPN daemon and its state isolated from the host.

## Topology

- Host tap `vm-tailscale` → `192.168.101.1/24`; guest → `192.168.101.2/24`.
- Resources: `cloud-hypervisor`, 256 MB RAM, 1 vCPU, vsock CID `11`.
- `autostart = false` — start on demand with `make run-tailscale` (`nix run .#tailscale-vm`).
- Tailscale state persists on the host at `/persist/var/lib/tailscale-vm`, shared into the guest over
  `virtiofs` (`→ /var/lib/tailscale`), so node identity survives guest restarts.

## Service

```nix
services.tailscale = {
  enable = true;
  useRoutingFeatures = "both";   # accept and advertise routes
};

boot.kernel.sysctl = {
  "net.ipv4.ip_forward" = 1;
  "net.ipv6.conf.all.forwarding" = 1;
};
```

The guest firewall opens UDP `41641` for the Tailscale WireGuard transport. `useRoutingFeatures = "both"`
plus IP forwarding lets the guest act as a subnet router / exit node.

## First run

```bash
make run-tailscale
# inside the guest, authenticate once:
sudo tailscale up
```

After the first `tailscale up`, the node key is stored in the persisted state directory and reused on
subsequent starts.
