# AI Stack

`volnix` runs a local, CUDA-accelerated AI stack plus a custom agent toolchain. The model services are
declared in
[`nixos/configuration.nix`](https://github.com/lowcache/volnixos/blob/main/nixos/configuration.nix).

## Ollama + Open WebUI

```nix
services.ollama = {
  enable = true;
  package = pkgs.ollama-cuda;
  home = "/home/lowcache";
  models = "/home/lowcache/Storage/ollama/models";
};

services.open-webui = {
  enable = true;
  port = 8080;
  environment.OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
};
```

Ollama runs as the `lowcache` user (so model files live under `~/Storage` without permission issues)
with a tuned environment:

| Variable                     | Effect                                                      |
| :--------------------------- | :--------------------------------------------------------- |
| `OLLAMA_FLASH_ATTENTION=1`   | Flash attention                                            |
| `OLLAMA_KEEP_ALIVE=5m`       | Unload idle models → release CUDA → dGPU RTD3 (0 W) suspend |
| `OLLAMA_NUM_PARALLEL=1`      | Single parallel request                                    |
| `CUDA_VISIBLE_DEVICES=0`     | Pin to the RTX 4050                                         |
| `OLLAMA_ORIGINS=*`           | Allow web origins (Open WebUI)                             |

Open WebUI is reachable at `http://127.0.0.1:8080`; `ffmpeg` is injected into its `PATH` for media
handling.

!!! tip "VRAM fit (RTX 4050, 6 GB)"
    `llama3.1:8b` Q4 is the practical interactive ceiling. MoE models such as `gpt-oss-20b` (MXFP4)
    also run — active experts in VRAM, inactive experts offloaded to RAM.

## Fooocus (Stable Diffusion)

A non-autostarting Docker OCI container provides image generation with GPU passthrough:

```nix
virtualisation.oci-containers.containers."fooocus" = {
  image = "ghcr.io/lllyasviel/fooocus:latest";
  autoStart = false;
  ports = [ "7865:7865" ];
  volumes = [ "/home/lowcache/Storage/ai-generation/fooocus:/content/data" ];
  environment = {
    CMDARGS = "--listen";
    DATADIR = "/content/data";
    config_path = "/content/data/config.txt";
    path_checkpoints = "/content/data/models/checkpoints/";
    path_loras = "/content/data/models/loras/";
    path_outputs = "/content/data/outputs/";
  };
  extraOptions = [ "--device" "nvidia.com/gpu=0" ];
};
```

Control it with the Fish aliases `stbldff-on` / `stbldff-off` (start/stop `docker-fooocus.service`).
Outputs persist via the symlink `~/Pictures/fromAi/outputs → ~/Storage/ai-generation/fooocus/outputs`.

## Agent CLIs

The user package set in
[`home/pkgs.nix`](https://github.com/lowcache/volnixos/blob/main/home/pkgs.nix) bundles AI tooling:
`claude-code`, `gemini-cli`, `claude-code-router`, `github-copilot-cli`, `rtk`, several MCP servers
(`mcp-nixos`, `mcp-gateway`, `github-mcp-server`, `playwright-mcp`, `context7-mcp`, …), and the
`llm-agents.nix` overlay. The `ai` / `ai-shell` Fish functions run any `llm-agents.nix` tool on the
fly. The custom curation/delegation layer is documented in [Agent Toolchain](../tooling/agents.md).
