{ pkgs, ... }:
{
  # Agent / MCP tooling on the phone — the subset of home/pkgs.nix `nixAi` that
  # has an aarch64-linux substitute at the current lock. Verified with
  # `nix build --dry-run` per package: every entry here is fetched, none is
  # compiled on-device.
  #
  # Kept as its own module on purpose. When a nixpkgs bump drops the aarch64
  # build for one of these, the fix is to comment out a line here rather than
  # to untangle it from the shared layer.
  #
  # Deliberately absent:
  #   github-copilot-cli   — no aarch64 build (evaluation error at this rev).
  #   antigravity          — evaluates on aarch64, but it is a desktop Electron
  #                          IDE and Nix-on-Droid has no display server. It
  #                          would add ~3.2 GB of GTK/X11 closure for a binary
  #                          that cannot launch.
  #   memd / tether / agent-scaffold — home/scripts.nix links these out of
  #                          /persist, which does not exist on Android. They
  #                          need a phone-local checkout before they can be
  #                          wired up.
  #
  # Absent because of the nixos-25.11 pin (see droid/README.md — glibc 2.42's
  # TCGETS2 isatty() is refused by Android SELinux, so the phone cannot track
  # unstable). These exist only in unstable at this lock:
  #   rtk, mcp-gateway, context7-mcp, mcp-server-fetch,
  #   mcp-server-sequential-thinking, llmfit, llm-agents.zaly
  # Do NOT reach into `inputs.nixpkgs` for them: they would come back linked
  # against glibc 2.42 and land in the same promptless/no-tty state the pin
  # exists to avoid. Re-add when the pin lifts, or when 25.11 gains them.
  home.packages =
    with pkgs;
    [
      claude-code
      claude-code-router
      codex

      # MCP servers. The phone-agent server itself is NOT here — it stays in the
      # Termux app, which is the only package Termux:API will talk to. See
      # droid/README.md.
      mcp-nixos
      github-mcp-server
    ]
    ++ (with pkgs.llm-agents; [
      # numtide/llm-agents.nix — same set volnix installs. The flake declares
      # aarch64-linux support and publishes aarch64 builds to cache.numtide.com,
      # which droid/default.nix adds as a substituter. Verified per package:
      # all fetched, none built.
      #
      # antigravity-cli supersedes gemini-cli, which is why gemini-cli is not in
      # the list above. Taken from llm-agents rather than nixpkgs: 1.1.8 vs 1.1.4,
      # and the llm-agents build is fully substitutable while the nixpkgs one is
      # not. This is the CLI — NOT the `antigravity` / `antigravity-ide` Electron
      # desktop app, which cannot run without a display server.
      antigravity-cli
      ccstatusline
      claude-plugins
      opencode
      cc-switch-cli
      parallel-cli
      toon
      happy-coder
    ]);
}
