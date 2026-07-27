# Phone Agent

The `phone-agent` NixOS module wires `volnix` to a **Galaxy S26 Ultra** running a Termux-based MCP
server, turning the phone into a set of remote tools and sensors the laptop can call over Tailscale.
The module lives in
[`nixos/phone-agent/`](https://github.com/lowcache/volnixos/blob/main/nixos/phone-agent/) and is
imported and enabled from
[`nixos/configuration.nix`](https://github.com/lowcache/volnixos/blob/main/nixos/configuration.nix).

It provides four capabilities, each an independently toggleable systemd **user** service, plus a
`phone-agent` CLI for ad-hoc tool calls:

- **MCP transport** — HTTP MCP over Tailscale, bearer-token authenticated.
- **Ingest** — periodic pull of staged files off the phone, integrity-checked.
- **Proximity lock** — lock the laptop when the phone leaves the desk (lock only).
- **Network routing** — derive a routing profile from the phone's current SSID (opt-in, off by default).

!!! note "Scope"
    This page documents the **laptop side** (the NixOS module declared in this repo). The phone-side
    MCP server is built on-device with Claude Code and is out of scope here — see
    [`nixos/phone-agent/README.md`](https://github.com/lowcache/volnixos/blob/main/nixos/phone-agent/README.md)
    and the phone repo's `PHONE-ENV.md` for that half.

## Wiring

```nix
# nixos/configuration.nix
imports = [ ./phone-agent ];

phone-agent = {
  enable = true;
  phoneTailscaleIP = "100.101.229.9";               # from the Tailscale Android app
  tokenFile = config.sops.secrets.phone_agent_token.path;
};
```

The bearer token is a [sops-nix](architecture/secrets.md) secret (`phone_agent_token`) materialized at
runtime; its value must match `~/.config/phone-agent/token` on the phone. `tokenFile` is typed `str`,
not `path`, on purpose — a `path` literal would copy the secret into the world-readable Nix store. The
module asserts `tokenFile` is set.

## Options

| Option | Default | Purpose |
| :--- | :--- | :--- |
| `enable` | `false` | Master switch for the subsystem. |
| `phoneTailscaleIP` | `100.101.229.9` | Tailscale IP of the phone MCP server. |
| `port` | `8462` | Phone MCP server port. |
| `tokenFile` | *(required)* | Path to the sops bearer-token file. |
| `ingestDir` | `/home/lowcache/ingest` | Laptop dir mirroring staged phone output. |
| `ollamaHost` | `volnix` | Hostname the phone uses to reach this laptop's Ollama (documentation only). |
| `enableIngestSync` | `true` | Periodic pull of staged files. |
| `enableIngestWatcher` | `true` | Process staged files as they land. |
| `enableProximityLock` | `true` | Lock on phone-away. |
| `enableNetworkRouting` | `false` | SSID-derived routing profile. |
| `proximityIntervalSec` | `5` | IMU poll interval for proximity. |
| `allowUnlock` | `false` | Experimental; logs intent only (see below). |

## The `phone-agent` CLI

`phone-agent <tool> [args-json]` calls a phone MCP tool and pretty-prints the result (errors surface as
`{error: …}`):

```bash
phone-agent phone.system.ping
phone-agent phone.sensor.read_imu '{"sample_count":10}'
phone-agent phone.npu.transcribe '{"audio_path":"/tmp/test.wav"}'
```

Health check the transport directly with `curl -sf http://<phoneTailscaleIP>:8462/health`.

## MCP gateway backend

The module writes a template to `/etc/phone-agent/gateway-peer.example.yaml` and emits a build-time
**warning** to register it — `~/.config/mcp-gateway/gateway.yaml` is hand-managed, so the module surfaces
the values rather than editing it for you:

```yaml
backends:
  phone-agent:
    transport: http
    url: http://<phoneTailscaleIP>:8462/mcp
    # Authorization: Bearer $(cat <tokenFile>)
    namespace: phone
```

## Ingest

`phone-ingest-sync` (oneshot + timer, every 2 min) pulls staged files off the phone via the
`phone.ingest.list` / `phone.ingest.fetch` MCP tools, base64-decodes each payload, **verifies its
sha256**, and only then moves it into `<ingestDir>/staged/` (deleting the phone-side copy). It exits
silently if the phone is unreachable. `phone-ingest-watcher` is a systemd path unit watching
`<ingestDir>/staged/*.json`; new files trigger `ingest-watcher.sh` to process them.

## Proximity lock

`phone-proximity-daemon` polls the phone's IMU every `proximityIntervalSec`. When the inferred motion
state transitions from `on_desk`/`stationary` to `walking`/`in_pocket`, it runs
`niri msg action lock-screen`.

!!! warning "Lock only — no auto-unlock"
    There is no safe programmatic unlock, so the daemon never unlocks. `allowUnlock` is experimental and
    intentionally a no-op: it only logs unlock *intent*, it does not unlock the session.

## Network routing

Off by default. When enabled, `phone-network-routing` reads the phone's current Wi-Fi SSID
(`phone.sensor.read_modem`), maps it to a `home` / `untrusted` / `secure` profile, and writes the result
to `/run/user/$UID/phone-agent/network-profile`, optionally starting a
`phone-network-profile@<profile>.service`.

!!! info "Ceiling"
    Profile derivation and the runtime file are in place; wiring the profile through to the
    [net-gate microvm](networking/net-gate.md) is not yet implemented.
