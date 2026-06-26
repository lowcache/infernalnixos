# ENVIRONMENT TOOLCHAIN — ON-DEMAND REFERENCE

Read per-subsystem when a task touches it; not loaded every session. The always-on
core (read/inbox rules, scratch policy, delegation triggers) lives in CLAUDE.md §X.

## Session hooks (`~/.claude/settings.json`)

| Event | Command | Effect |
| --- | --- | --- |
| `SessionStart` | `agent-scaffold` | Scaffold `.model/` (+ `.memory/` via `memd init`) at git root. Idempotent. |
| `SessionStart` | `memd hook session-start` | Inject the memory brief. |
| `PreCompact` | `memd hook pre-compact` | Capture transcript before compaction. |
| `SessionEnd` | `memd hook session-end` | Detached `memd sync` to distill the session. |

Systemd user timer `memd-sweep` (~30 min) runs session-independently: catches up
stale projects, ingests `inbox/`, prunes to `archive/`, auto-detects new repos.

## memd — project memory curator

Source `~/.nix-config/scripts/memd/` (README authoritative). Owns
`.memory/{state,decisions,mistakes,todo}.md` + `archive/` + `inbox/`, distilled
from transcripts by a headless `claude -p` curator.

* Never edit `.memory/*` directly — manual edits race the curator and break its
  invariants (frontmatter, append-only `mistakes.md`, shrink guard, size budgets,
  per-project flock, apply-then-advance cursors). Write only via `inbox/`.
* Missing scaffolding: `memd init [path]`. Introspection: `memd status`. History:
  `git log -- .memory/`.
* Reads claude-code JSONL + antigravity-cli SQLite natively; all digests pass a
  credential-redaction filter. Distill backend re-pointable via `curator_cmd` in
  `~/.config/memd/config.json`.

## agent-scaffold — project contract bootstrap

Source `~/.nix-config/scripts/agent-scaffold/` (fish, wired to `SessionStart`). At a
git work-tree root (never `$HOME`) renders `templates/MODEL.md` three times —
`.model/{CLAUDE,AGENTS,GEMINI}.md` — and runs `memd init` if `.memory/` is absent.
Creates only missing files. Manual: `agent-scaffold [DIR]` (default `$PWD`).

## tether — Claude→Gemini delegation

Global `tether` (home `~/.nix-config/.model/agent-tether/`; read its `PROTOCOL.md`
before first use). Claude orchestrates (decomposes, briefs, integrates, owns all
decisions + final output); Gemini via `agy` is the worker (`RESULT / EVIDENCE /
BLOCKERS`).

* `tether run [-m pro|pro-low|flash|flash-high|flash-low] [-d DIR] [-t TASK] [-y]
  [--timeout SECS] "BRIEF"` — new delegation (`BRIEF` may be `-` for stdin).
* `tether continue TASK "FOLLOW-UP"` (needs `-t` on the original);
  `tether status|log [N]|models` — introspection.
* Never delegate: architecture, `.memory/` curation, destructive/system ops, final
  answers. Core constraints (`~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`) are never
  suspended through the protocol.
* Gotcha: `agy` can't register hidden dirs; tether auto-maps `~/.nix-config` →
  `~/volnix`. Pass `-d` for any other hidden path.

## `.model/` directory

Per-project agent contracts, out of the source tree: scaffolded `CLAUDE.md` (read
first — project scope), `AGENTS.md`, `GEMINI.md`. Project instructions live here and
must not contradict `~/.claude/`. Decisions → `.memory/inbox/` for the curator.
Harness-created settings (`.claude/`) also belong under `.model/`.

## Token compression
TODO: replace the retired RTK proxy. TOFIX: maximize compression without modulating
output. (No PreToolUse compression hook currently active.)

## mcp-gateway — consolidated MCP surface

One `mcp-gateway` server fronts multiple backends behind `gateway_*` tools. Prefer
it over per-server MCPs. Config: `~/.config/mcp-gateway/gateway.yaml` (hand-edited,
not nix-managed). Backends: `nixos`, `sequential-thinking`, `github`, `markitdown`,
`playwright`, `context7`, `open-websearch`, `server-fetch`. Discovery:
`gateway_search_tools` → `gateway_invoke(server,tool,args)`.

* **Lazy-enum (verified 2026-06-15):** `tools_count: 0` and missing search hits do
  NOT mean broken — tools materialize on first `gateway_list_tools <server>` or
  `gateway_invoke`. Confirm with a direct call before diagnosing failure.
* **Hot-reload:** `gateway_reload_config` is server-level only; a backend `command`
  change needs respawn (`gateway_kill_server`+`gateway_revive_server`, or new
  session). "No changes" on reload ≠ a command edit is live.
* **playwright on NixOS (verified 2026-06-15):** nixpkgs `playwright-mcp` bakes a
  read-only `PLAYWRIGHT_BROWSERS_PATH` then tries to install chrome-for-testing
  there → never launches. Fix: route through `scripts/playwright-mcp-nix` (pins
  `--executable-path` to nix chromium, headless+isolated). nix chromium runs
  headless here; **brave headless hangs** — don't use brave for screenshots.

## Scratch space

Full policy in CLAUDE.md §X. In short: heavy/multi-step scratch → `~/Storage/tmp`,
not tmpfs `/tmp` (~4 GB, wiped on boot); set `TMPDIR` for spillers; clean up after.
Symptom if ignored: `ENOSPC` on the task dir.
