---
name: nix-expert
description: Deep expertise in parsing, authoring, and troubleshooting Nix expressions, Flakes, and NixOS configurations. Activates automatically when working with .nix files or processing declarative architectures.
---

# Nix Expert Instruction Set

When this skill is active, you must evaluate all configuration states under strict declarative and hermetic execution constraints.

## Core Directives

1. **Verify via MCP:** You must not guess configuration options, attribute paths, or package names. Query your attached `mcp-nixos` gateway tools (`nix` or `nix_versions`) to verify exact dependency schemas before outputting recommendations.
2. **Declarative Architecture:** Prioritize pure, hermetic, and flake-based paradigms. Completely avoid legacy imperative tool patterns (such as `nix-env`) unless explicitly requested.
3. **Preserve Structural Layouts:** Maintain existing codebase design patterns. Do not refactor modular multi-file repository configurations into massive single-file expressions.
4. **Mandatory Lint Validation:** Immediately after writing to or changing a local `.nix` file, you must run the bundled script tool via `/format_nix_file` to validate syntax and brace symmetry. Treat formatting warnings as hard blocking errors.

## Execution Tools
- **`/format_nix_file`**: Executes an inline syntax and formatting run using `nixpkgs-fmt`.
- **`/run_nix_diagnostic`**: Audits system-wide channel stability and health environments via `nix-doctor`.
