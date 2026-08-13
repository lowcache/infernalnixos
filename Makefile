# Vol NixOS Makefile
# Unifies system rebuilds, MicroVM guest management, SOPS secrets, and maintenance tasks.

# --- Configuration & Environment Defaults ---
HOST           ?= volnix
REBUILD_TMPDIR ?= $(HOME)/Storage/tmp
FLAKE_DIR      := /persist/home/lowcache/.nix-config

# --- Dotfiles Subtree Config ---
DOTS_PREFIX       ?= dots
DOTS_REMOTE       ?= dotfiles
DOTS_BRANCH       ?= main
DOTS_SPLIT_BRANCH ?= dots-history

# --- SOPS / Secret Management ---
SOPS_FILE         ?= secrets/secrets.yaml
SOPS_AGE_KEY_FILE ?= ~/.config/sops/age/keys.txt

# --- Documentation site (MkDocs Material) ---
DOCS_PROJECT ?= wiki
DOCS_REMOTE  ?= pgs.sh

# Ephemeral MkDocs Material environment from the flake's own pinned nixpkgs
MKDOCS := nix shell --impure --expr 'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux; in pkgs.python313.withPackages (ps: [ ps.mkdocs-material ])' -c mkdocs

# --- All Targets Declared PHONY ---
.PHONY: help switch switch-detached build test dry-activate boot \
        droid-check droid-plan droid-switch \
        run-netgate run-tailscale \
        sops-edit sops-rekey sops-view \
        check fmt update update-nixpkgs trash \
        git comm push \
        dots-log dots-split dots-remote dots-push dots-pull \
        docs-serve docs-build docs-deploy

.DEFAULT_GOAL := help

## :help: ..........: Display available targets and descriptions
help:
	@echo ""	
	@echo "Vol NixOS Helper Makefile"
	@echo "Usage- make [command]"
	@sed -n 's/^##//p' $(MAKEFILE_LIST) | column -t -s ':' -o '' -C color=yellow,right -C color=white,left -C color=white,left -C color=green

# ==============================================================================
# System Operations
# ==============================================================================
## System Operations
## :switch: ..........: Rebuild and switch system live (Default HOST- volnix)
switch:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild switch --flake .#$(HOST) --option fallback true

## :switch-detached: ..........: Switch as a detached system unit (survives session manager/greetd teardowns)
switch-detached:
	sudo systemd-run --collect --unit=nixos-switch \
		--setenv=TMPDIR=$(REBUILD_TMPDIR) \
		--setenv=SUDO_UID=$$(id -u) \
		--setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin \
		nixos-rebuild switch --flake $(FLAKE_DIR)/#$(HOST)
	@echo ""
	@echo "++ Switch running detached as system unit 'nixos-switch'."
	@echo "++ Follow:  journalctl -u nixos-switch -f"
	@echo "++ Status:  systemctl status nixos-switch"

## :build: ..........: Build system configuration without switching
build:
	TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild build --flake .#$(HOST)

## :test: ..........: Temporarily switch to configuration (no boot entry)
test:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild test --flake .#$(HOST)

## :dry-activate: ..........: See what service transitions will happen
dry-activate:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild dry-activate --flake .#$(HOST)

## :boot: ..........: Stage the rebuild for the next boot
boot:
	sudo TMPDIR=$(REBUILD_TMPDIR) nixos-rebuild boot --flake .#$(HOST)

# ==============================================================================
# Nix-on-Droid (aarch64 phone target)
# ==============================================================================
# The phone builds and switches itself — volnix has no aarch64 emulation, so
# these laptop-side targets are evaluation gates only. `droid-switch` is what
# you run ON the phone, from a clone of this repo.
#
# `--impure` is required: nix-on-droid's own CLI passes it too, because the
# bootstrap proot binary is referenced via `builtins.storePath`.

# NOTE: the '#' must be escaped — in a Make variable assignment an unescaped
# '#' starts a comment and would silently truncate this to '.'.
DROID_ATTR := .\#nixOnDroidConfigurations.default
## Nix-On-Droid
## :droid-check: ..........: Evaluate the phone's Home Manager layer from the laptop (no build)
droid-check:
	@echo "==Evaluating $(DROID_ATTR) home-manager layer (aarch64-linux)=="
	nix eval --impure --raw \
		'$(DROID_ATTR).config.home-manager.config.home.activationPackage.drvPath'
	@echo ""
	@echo "++ Evaluates clean. The system layer's uid/gid probe is import-from-"
	@echo "++ derivation and can only run on the device."

## :droid-plan: ..........: List what the phone would fetch vs. compile (dry-run, laptop-side)
droid-plan:
	nix build --impure --dry-run \
		'$(DROID_ATTR).config.home-manager.config.home.activationPackage'

## :droid-switch: ..........: Build+activate on the PHONE (run this inside Nix-on-Droid)
droid-switch:
	nix-on-droid switch --flake .

# ==============================================================================
# MicroVM Guest Operations
# ==============================================================================
## MicroVM
## :run-netgate: ..........: Start the Tor net-gate MicroVM runner
run-netgate:
	nix run .#net-gate

## :run-tailscale: ..........: Start the Tailscale-vm MicroVM runner
run-tailscale:
	nix run .#tailscale-vm

# ==============================================================================
# Secrets Management (SOPS / Age)
# ==============================================================================
## Secret Management
## :sops-edit: ..........: Decrypt and edit SOPS secrets file
sops-edit:
	SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) sops $(SOPS_FILE)

## :sops-rekey: ..........: Re-encrypt secrets across public host keys listed in .sops.yaml
sops-rekey:
	SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) sops updatekeys $(SOPS_FILE)

## :sops-view: ..........: Print decrypted secrets without opening an editor
sops-view:
	SOPS_AGE_KEY_FILE=$(SOPS_AGE_KEY_FILE) sops -d $(SOPS_FILE)

# ==============================================================================
# Flake & Code Maintenance
# ==============================================================================
## Flake & Code Maintenance
## :check: ..........: Check flake lock and schema validity
check:
	nix flake check
	@echo "==Dead Code & Antipattern Checks=="
	@echo "==Running Deadnix=="
	@deadnix --fail .
	@echo "==Running Statix Check=="
	@statix check .

## :fmt: ..........: Auto-format all Nix expressions
fmt:
	nix fmt
	@echo "==Statix Fix=="
	@statix fix .

## :update: ..........: Update all flake inputs
update:
	nix flake update

## :update-nixpkgs: ..........: Update only the nixpkgs input
update-nixpkgs:
	nix flake update nixpkgs

## :trash: ..........: Delete system profile generations older than 7 days and clean store
trash:
	@echo "++ Deleting system profile generations older than 7 days..."
	sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations 7d
	@echo "++ Running Nix store garbage collection..."
	nix-store --gc

# ==============================================================================
# Git Operations
# ==============================================================================
## Git Ops
## :git: ..........: Automated procedure to commit changes and sync with remote
git:
	@run() { $(MAKE) --no-print-directory push && $(MAKE) --no-print-directory comm && $(MAKE) --no-print-directory push; }; \
	if ssh-add -l >/dev/null 2>&1; then \
		run; \
	else \
		eval "$$(ssh-agent -s)" >/dev/null 2>&1; \
		trap 'kill "$$SSH_AGENT_PID" 2>/dev/null' EXIT; \
		echo "++ Starting ssh-agent (passphrase required once)..."; \
		ssh-add ~/.ssh/id_ed25519 || exit 1; \
		run; \
	fi && echo "++ Git Repo Updated."

## :comm: ..........: Scan repo, stage changes, and prompt for commit message
comm:
	@echo "++ Scanning Repo..."; \
	git add .; \
	echo "++ Staging Commit..."; \
	if read -p "++ Enter Commit Message: " cm && [ -n "$$cm" ]; then \
		echo ""; \
		git commit -m "$$cm" || true; \
	else \
		echo "++ ERROR: Commit Message Invalid."; \
		echo "++ Aborting..."; \
		exit 1; \
	fi

## :push: ..........: Push local commits to remote using ssh-agent
push:
	@echo "++ Pushing to Remote..."; \
	if ssh-add -l >/dev/null 2>&1; then \
		git push; \
	else \
		echo "++ No usable ssh-agent found; starting one (passphrase required)..."; \
		eval "$$(ssh-agent -s)" >/dev/null 2>&1; \
		ssh-add ~/.ssh/id_ed25519 && git push; rc=$$?; \
		kill "$$SSH_AGENT_PID" 2>/dev/null; \
		exit $$rc; \
	fi

# ==============================================================================
# Dotfiles Subtree Operations
# ==============================================================================
## Dotfiles
## :dots-log: ..........: Show git log scoped to dots/ prefix
dots-log:
	git log --oneline -- $(DOTS_PREFIX)

## :dots-split: ..........: Regenerate the projection branch of dots/
dots-split:
	@echo "Regenerating '$(DOTS_SPLIT_BRANCH)' projection of $(DOTS_PREFIX)/ ..."
	-@git branch -D $(DOTS_SPLIT_BRANCH) >/dev/null 2>&1 || true
	git subtree split --prefix=$(DOTS_PREFIX) -b $(DOTS_SPLIT_BRANCH)

## :dots-remote: ..........: Add standalone dotfiles remote (Usage- make dots-remote URL=<url>)
dots-remote:
	@test -n "$(URL)" || { echo "Usage: make dots-remote URL=<git-url>"; exit 1; }
	git remote add $(DOTS_REMOTE) "$(URL)"
	@echo "Added remote '$(DOTS_REMOTE)' -> $(URL)"

## :dots-push: ..........: Publish dots/ history to remote
dots-push:
	git subtree push --prefix=$(DOTS_PREFIX) $(DOTS_REMOTE) $(DOTS_BRANCH)

## :dots-pull: ..........: Merge changes from remote back into dots/
dots-pull:
	git subtree pull --prefix=$(DOTS_PREFIX) $(DOTS_REMOTE) $(DOTS_BRANCH)

# ==============================================================================
# Documentation Wiki (MkDocs Material -> pgs.sh)
# ==============================================================================
## MkDocs Volnixos Wiki
## :docs-serve: ..........: Live-preview the docs site locally (127.0.0.1 @ port-8000)
docs-serve:
	$(MKDOCS) serve

## :docs-build: ..........: Build the static site strictly to ./site
docs-build:
	$(MKDOCS) build --strict

## :docs-deploy: ..........: Build and rsync ./site to remote documentation host
docs-deploy: docs-build
	rsync --delete -rv ./site/ $(DOCS_REMOTE):/$(DOCS_PROJECT)
