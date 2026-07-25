# Agent Guide (CLAUDE.md)
Repository: **Vol NixOS**
Read this file and the contents of `./.memory/` to gain current state and operational knowledge.
`.model/.claude/` directory contains `settings.local.json` & `.mcp.json` 

## Docs
Full documentation is located in `docs/`
`mkdocs` is utilized to publish docs in wiki format live through ssh on the pico.sh platform
WIKI URL: `https://volnixos-wiki-pgs.sh`

## Makefile
All helper commands and actions are available in a Makefile in the root directory of the repo
Commands that are included in the Makefile fall under the following categories:

- System Operations
- MicroVM Guest Operations
- Flake & Code Maintenance
- Dotfile Subtree Actions
- Colorscheme Control
- Documentation Wiki

## Nix 

Never invent: 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
- options 
-                            attribute paths 
- package names 

Always verify using the attached `mcp-nixos` tools (`nix` / `nix_versions`) before producing configuration changes.

the nix-expert agentic swarm skills should be used in instances of:
`Large additions to the config || Large removals from the config || additions and removals from the config` 
Nix-expert siills are meant to be used in tandem with an orchestrator and 5 subagents:

- nix-expert - orchestrator  
- nix-flake-expert  - subagent
- nix-home-manager-expert  - subagent
 b- nix-impermanence-expert  - subagent
- nix-options-expert  - subagent
- nix-virtualization-expert - subagent

When editing: 

- run syntax checks 
- produce idiomatic Nix 
- format with `nixfmt` or `nixpkgs-fmt`

Home-Manager:
Never generate traditional Home Manager outputs into `~/.config` unless explicitly requested. 
Preserve out-of-store symlinks to enable hot-reloading.

maintain choices where the config remains: 

- declarative 
- hermetic 
- flake-based 

Avoid imperative tooling (e.g. `nix-env`) unless explicitly requested. 
Preserve the existing modular layout. 
Do not collapse modules into monolithic files. 

Nixos-Rebuild policy:
The user should be the only one that runs: `sudo nixos-rebuild switch --flake .#volnixos`
check whether graphical components (`glibc`, display manager, `greetd`, etc.) will restart and terminate the active graphical session and can kill the rebuild.
If applicable:

  - warn the user
  - recommend switching TTY, or running the nixos-rebuild detached. 
  - `nixos-rebuild {build, dry-activate, boot} --flake .#volnix` are available for testing, dry-runs, and to ensure an error free switch 

  
## volinit
the terminal init banner graphic and sysinfo application

- Repository:
  `https://github.com/lowcache/volinit`
- Added as a flake input.
- Local checkout:
  `/home/lowcache/CodeRepo/volinit`

Changes require:

1. commit/push upstream
2. `nix flake update volinit`
3. rebuild

---

## Rules & Directives:

### A. Project MemFS (memd)

`./.memory/` is owned by and curated by **memd**.
Sessions **read** memory.
memd **writes** memory.

Read before implementation:

- `.memory/state.md`
- `.memory/decisions.md`
- `.memory/mistakes.md`
- `.memory/todo.md`

Reference only:

- `.memory/archive/`

Write only to:

- `.memory/inbox/` using dated notes

Never manually edit curated memory or YAML frontmatter unless explicitly instructed by lowcache.
  
### B. MCP-GATEWAY 

Primary MCP aggregation server.
Always extend the mcp-gateway server instead of implementing stand alone tools/mcp-servers
Tools include:

- mcp-nixos
- GitHub
- MarkItDown
- Playwright
- context7
- open-websearch
- server-fetch
- sequential-thinking

**NOTE:**
Noctalia mcp server for the `noctalia-claude-plugin` in `.model/.claude/.mcp.json` is the only mcp server that is not run under the mcp-gateway

### C. Git 

- Commit normal code changes. 
- memd commits `.memory/inbox` 

Commit messages should: 

- avoid model branding 
- use first-person 
- represent the user (`lowcache`)

## F. Nvidia / CUDA

- `ollama = pkgs.ollama-cuda`
- Preserve

`OLLAMA_KEEP_ALIVE=5m`

Never:
 
- remove the OLLAA_KEEP_ALIVE=5m
- introduce daemons that continuously poll `/dev/nvidia*`

Reason: preserves RTD3 suspend and prevents excessive battery drain.



