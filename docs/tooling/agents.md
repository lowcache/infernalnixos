# Agent Toolchain

A self-contained toolchain for AI-agent sessions lives in
[`scripts/`](https://github.com/lowcache/volnixos/tree/main/scripts) and `.model/`. It is deployed as
out-of-store symlinks in `~/.local/bin` via
[`home/scripts.nix`](https://github.com/lowcache/volnixos/blob/main/home/scripts.nix), so the three
commands are available in **every** project, not just this repo.

```mermaid
flowchart LR
    SS["agent CLI session"] --> AS["agent-scaffold"]
    AS --> M[".model/<br/>CLAUDE · AGENTS · GEMINI.md"]
    AS --> MEM[".memory/ (memd init)"]
    MEM --> CUR["memd curator<br/>distills transcripts"]
    CUR --> FILES["state · decisions · mistakes · todo .md"]
    CLAUDE["Claude (orchestrator)"] -->|brief| TETHER["tether"]
    TETHER -->|agy| GEM["Gemini (worker)"]
    GEM -->|RESULT / EVIDENCE / BLOCKERS| CLAUDE
```

## memd — project-memory curator

`memd` (its own repo at `~/CodeRepo/memd`) autonomously distills AI session transcripts into a
project's `.memory/` files. It is deployed as a home-manager module (`services.memd`), running from
the pinned `/nix/store` copy with automatic periodic sweep timers.

| File                  | Holds                                              |
| :-------------------- | :------------------------------------------------ |
| `.memory/state.md`    | Live status, configs, ports, active workarounds    |
| `.memory/decisions.md`| Canonical architecture decisions                   |
| `.memory/mistakes.md` | Append-only audit log of bugs/issues               |
| `.memory/todo.md`     | Open tasks                                          |
| `.memory/inbox/`      | Write interface — drop dated notes for the curator |

- **Read** the memory files at session start. **Write** only by dropping a markdown note in
  `.memory/inbox/`; the next sweep ingests and deletes it.
- A `memd-sweep` systemd **user timer** (~30 min, managed by `services.memd` in `home/default.nix`)
  catches up stale projects, ingests inboxes, prunes oversized files, and detects new git repos.
- Session hooks (`SessionStart`, `SessionEnd`, `PreCompact`) wire memd into Claude Code.

!!! danger "Never hand-edit `.memory/`"
    The curator maintains invariants (frontmatter, append-only `mistakes.md`, size budgets, per-project
    locks, apply-then-advance cursors). Manual edits race the background runs. Scaffold with
    `memd init`, never by hand.

## tether — Claude → Gemini delegation

`tether` (standalone tool in its own repo, `~/CodeRepo/tether`; put on `PATH` as
`~/.local/bin/tether` by [`home/scripts.nix`](https://github.com/lowcache/volnixos/blob/main/home/scripts.nix))
lets Claude (the **orchestrator**) hand scoped task briefs to Gemini (the **worker**) via `agy`. The
worker executes literally and reports in a `RESULT / EVIDENCE / BLOCKERS` format.

```bash
tether run [-m pro|pro-low|flash|flash-high|flash-low] [-d DIR] [-t TASK] [-y] [-f FILE]... [-o OUT] "BRIEF"
tether ask  [-d DIR] [-f FILE]... "QUESTION"   # one-shot: flash tier, RESULT-only
tether continue TASK [-f FILE]... [-o OUT] "FOLLOW-UP"
tether status [TASK] | log [N] | models
```

- Default workdir is `$PWD`; paths under `~/.nix-config` auto-map to the non-hidden `~/volnix` alias
  (the Antigravity CLI rejects hidden workspace paths).
- `-f FILE` embeds a file's contents inline so the worker never tool-reads it (avoids the read-timeout)
  and the bytes never enter the orchestrator's context; `-o OUT` writes the report to a file.
- The full contract is in `~/CodeRepo/tether/PROTOCOL.md`.

!!! note "Never delegate"
    Architecture decisions, `.memory/` curation, destructive/system operations, and final
    user-facing answers stay with the orchestrator.

## agent-scaffold — project bootstrap

`agent-scaffold`
([`scripts/agent-scaffold/`](https://github.com/lowcache/volnixos/tree/main/scripts/agent-scaffold)) is
a Fish script that, at any git root, idempotently renders `.model/{CLAUDE,AGENTS,GEMINI}.md` from a
single template and runs `memd init` when `.memory/` is absent. It runs on Claude Code `SessionStart`
and via the `agy` Fish wrapper before Antigravity launches — deliberately **not** a `cd`/`$PWD` hook,
so merely entering a third-party repo never litters it with scaffolding.

> This documentation site itself was produced with this toolchain — the Desktop section was drafted by
> Gemini through `tether`.
