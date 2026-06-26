# Vol NixOS Makefile
# Unifies system rebuilds, MicroVM guest management, and maintenance tasks

HOST ?= volnix

# Stage rebuild temp on the fast Storage NVMe, not the 4G RAM tmpfs root.
# sudo resets the environment, so pass TMPDIR explicitly on privileged targets.
# (Daemon-internal build temp is set separately to /nix/tmp in configuration.nix,
# since nixbld users can't traverse the 0700 home that ~/Storage lives under.)
REBUILD_TMPDIR ?= $(HOME)/Storage/tmp

# --- Dotfiles subtree config (override on the command line if needed) ---
DOTS_PREFIX       ?= dots
DOTS_REMOTE       ?= dotfiles
DOTS_BRANCH       ?= main
DOTS_SPLIT_BRANCH ?= dots-history

# --- Colorscheme / theme workflow paths ---
II_DIR      := dots/illogical-impulse
THEMES_DIR  := $(II_DIR)/themes
SCRIPTS_DIR := $(II_DIR)/scripts
PYTHON      ?= python3

# --- Documentation site (MkDocs Material) ---
DOCS_PROJECT ?= wiki
DOCS_REMOTE  ?= pgs.sh
# Ephemeral MkDocs Material env from the flake's own pinned nixpkgs (no global install).
MKDOCS = nix shell --impure --expr 'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux; in pkgs.python313.withPackages (ps: [ ps.mkdocs-material ])' -c mkdocs

.PHONY: help switch switch-detached build test dry-activate boot check fmt update update-nixpkgs gc run-netgate run-tailscale ghc \
        dots-log dots-split dots-remote dots-push dots-pull \
        theme-list theme-apply theme-check theme-new \
        docs-serve docs-build docs-deploy

help:
	@echo "Vol NixOS Helper Makefile"
	@echo ""
	@echo "System Operations:"
	@echo "  make switch         Rebuild and switch system live (Default HOST: $(HOST))"
	@echo "  make switch-detached  Switch as a detached system unit (survives a session/greetd"
	@echo "                        teardown mid-rebuild); follow: journalctl -u nixos-switch -f"
	@echo "  make build          Build system configuration without switching"
	@echo "  make test           Temporarily switch to configuration (no boot entry)"
	@echo "  make dry-activate   See what service transitions will happen"
	@echo "  make boot           stage the rebuild for the next boot"
	@echo ""
	@echo "MicroVM Guest Operations:"
	@echo "  make run-netgate    Start the Tor net-gate MicroVM runner"
	@echo "  make run-tailscale  Start the Tailscale-vm MicroVM runner"
	@echo ""
	@echo "Flake & Code Maintenance:"
	@echo "  make check          Check flake lock and schema validity"
	@echo "  make fmt            Auto-format all Nix expressions using nixpkgs-fmt"
	@echo "  make update         Update all flake inputs"
	@echo "  make update-nixpkgs Update only the nixpkgs input"
	@echo "  make gc             Garbage collect older Nix store derivations"
	@echo "  make ghc            Adds changes and creates commit with generic description"
	@echo ""
	@echo "Dotfiles Subtree (independent history for $(DOTS_PREFIX)/, single repo):"
	@echo "  make dots-log       Show history scoped to $(DOTS_PREFIX)/ (read-only, no remote needed)"
	@echo "  make dots-split     (Re)generate the '$(DOTS_SPLIT_BRANCH)' projection branch of $(DOTS_PREFIX)/"
	@echo "  make dots-remote URL=<git-url>   Add the standalone '$(DOTS_REMOTE)' remote (one-time)"
	@echo "  make dots-push      Publish $(DOTS_PREFIX)/ history to $(DOTS_REMOTE)/$(DOTS_BRANCH)"
	@echo "  make dots-pull      Merge changes from $(DOTS_REMOTE)/$(DOTS_BRANCH) back into $(DOTS_PREFIX)/"
	@echo ""
	@echo "Colorscheme / Themes (in $(THEMES_DIR)):"
	@echo "  make theme-list                 List available themes"
	@echo "  make theme-apply THEME=<name>   Apply a theme by name (regenerates + reloads)"
	@echo "  make theme-check THEME=<name>   Validate a theme (hex + dangling refs + completeness)"
	@echo "  make theme-new NAME=\"My Theme\" [COLORS=\"#a #b ...\"] [FROM=<file>] [APPLY=1] [FORCE=1]"
	@echo "                                  Generate a new standards-compliant theme from colors"
	@echo ""
	@echo "Documentation Wiki (MkDocs Material -> $(DOCS_REMOTE)):"
	@echo "  make docs-serve     Live-preview the docs site locally (http://127.0.0.1:8000)"
	@echo "  make docs-build     Build the static site to ./site (strict)"
	@echo "  make docs-deploy    Build then rsync ./site to $(DOCS_REMOTE):/$(DOCS_PROJECT)"

switch:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild switch --flake .#$(HOST) --option fallback true

# Detached switch: run the activation as a transient SYSTEM service under PID1,
# fully decoupled from the graphical/login session. If the rebuild restarts the
# session manager (greetd) or the terminal dies, the switch keeps running to
# completion instead of aborting mid-activation (see .memory mistake #1). Use for
# rebuilds that touch the session bus, display manager, or graphics stack.
# --collect reaps the unit when done; pass TMPDIR via --setenv since the service
# starts from a clean environment.
switch-detached:
	sudo systemd-run --collect --unit=nixos-switch --setenv=TMPDIR=$(REBUILD_TMPDIR) --setenv=SUDO_UID=$$(id -u) nixos-rebuild switch --flake /persist/home/lowcache/.nix-config/#$(HOST)
	@echo ""
	@echo ">>> Switch running detached as system unit 'nixos-switch'."
	@echo ">>> Follow:  journalctl -u nixos-switch -f"
	@echo ">>> Status:  systemctl status nixos-switch"

build:
	TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild build --flake .#$(HOST)

test:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild test --flake .#$(HOST)

dry-activate:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild dry-activate --flake .#$(HOST)

boot:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild boot --flake .#$(HOST)

run-netgate:
	nix run .#net-gate

run-tailscale:
	nix run .#tailscale-vm

check:
	nix flake check

fmt:
	find . -name "*.nix" -exec nixpkgs-fmt {} +

update:
	nix flake update

update-nixpkgs:
	nix flake update nixpkgs

gc:
	@echo "Deleting system profile generations older than 7 days..."
	sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations 7d
	@echo "Running Nix store garbage collection..."
	nix-store --gc

ghc:
	git add .
	git commit -m "Minor Updates"

# --- Dotfiles subtree -------------------------------------------------------
# dots-log and dots-split work with no remote. dots-push/dots-pull need the
# remote set up once via `make dots-remote URL=...`.

dots-log:
	git log --oneline -- $(DOTS_PREFIX)

dots-split:
	@echo "Regenerating '$(DOTS_SPLIT_BRANCH)' projection of $(DOTS_PREFIX)/ ..."
	-@git branch -D $(DOTS_SPLIT_BRANCH) >/dev/null 2>&1 || true
	git subtree split --prefix=$(DOTS_PREFIX) -b $(DOTS_SPLIT_BRANCH)

dots-remote:
	@test -n "$(URL)" || { echo "Usage: make dots-remote URL=<git-url>"; exit 1; }
	git remote add $(DOTS_REMOTE) "$(URL)"
	@echo "Added remote '$(DOTS_REMOTE)' -> $(URL)"

dots-push:
	git subtree push --prefix=$(DOTS_PREFIX) $(DOTS_REMOTE) $(DOTS_BRANCH)

dots-pull:
	git subtree pull --prefix=$(DOTS_PREFIX) $(DOTS_REMOTE) $(DOTS_BRANCH)

# --- Colorscheme / theme workflow -------------------------------------------
# THEME is a bare name (no path, no .json). NAME is a display name for new themes.
# COLORS is a single quoted string of hex codes (bare '#' args become shell comments).

theme-list:
	@ls -1 $(THEMES_DIR)/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$$//' || echo "(none)"

theme-apply:
	@test -n "$(THEME)" || { echo "Usage: make theme-apply THEME=<name>   (see: make theme-list)"; exit 1; }
	$(PYTHON) $(SCRIPTS_DIR)/apply_theme.py $(THEMES_DIR)/$(THEME).json true

theme-check:
	@test -n "$(THEME)" || { echo "Usage: make theme-check THEME=<name>   (see: make theme-list)"; exit 1; }
	$(PYTHON) $(SCRIPTS_DIR)/check_theme.py $(THEMES_DIR)/$(THEME).json

theme-new:
	@test -n "$(NAME)" || { echo "Usage: make theme-new NAME=\"My Theme\" [COLORS=\"#a #b\"] [FROM=<file>] [APPLY=1] [FORCE=1]"; exit 1; }
	$(PYTHON) $(SCRIPTS_DIR)/make_theme.py --name "$(NAME)" \
		$(if $(COLORS),--colors "$(COLORS)") \
		$(if $(FROM),--from "$(FROM)") \
		$(if $(APPLY),--apply) \
		$(if $(FORCE),--force)

# --- Documentation wiki -----------------------------------------------------
# Builds with MkDocs Material from the flake's pinned nixpkgs and deploys to
# pgs.sh over SSH+rsync (project URL: https://<user>-$(DOCS_PROJECT).pgs.sh).

docs-serve:
	$(MKDOCS) serve

docs-build:
	$(MKDOCS) build --strict

docs-deploy: docs-build
	rsync --delete -rv ./site/ $(DOCS_REMOTE):/$(DOCS_PROJECT)

