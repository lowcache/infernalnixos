# Secrets — sops-nix + age

Secrets are managed with [`sops-nix`](https://github.com/Mic92/sops-nix) and **age** identities. The
encrypted stores `nixos/host-secrets.yaml` (host) and `nixos/vm-secrets.yaml` (MicroVM guests, wired
in `nixos/vms.nix`) are safe to commit; they are decrypted at activation into `/run/secrets/<name>`.

## Configuration

From [`nixos/configuration.nix`](https://github.com/lowcache/volnixos/blob/main/nixos/configuration.nix):

```nix
sops = {
  defaultSopsFile = ./host-secrets.yaml;
  defaultSopsFormat = "yaml";
  age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  secrets = {
    user_password = { neededForUsers = true; };
    root_password = { neededForUsers = true; };
    gemini_api_key = { owner = "lowcache"; };
    github_token  = { owner = "lowcache"; };
  };
};
```

| Secret           | Decryption target                | Used by                                   |
| :--------------- | :------------------------------- | :---------------------------------------- |
| `user_password`  | user creation (`neededForUsers`) | `users.users.lowcache.hashedPasswordFile` |
| `root_password`  | user creation (`neededForUsers`) | `users.users.root.hashedPasswordFile`     |
| `gemini_api_key` | `/run/secrets/gemini_api_key`    | exported as `GEMINI_API_KEY` in Fish      |
| `github_token`   | `/run/secrets/github_token`      | exported as `GITHUB_TOKEN` in Fish        |

The API keys are exported at shell start in
[`home/shell.nix`](https://github.com/lowcache/volnixos/blob/main/home/shell.nix) only if the runtime
secret file is readable:

```fish
test -r /run/secrets/gemini_api_key
and set -gx GEMINI_API_KEY (cat /run/secrets/gemini_api_key)
```

## Keys

- **Host key** — decrypts at boot: `/persist/etc/ssh/ssh_host_ed25519_key` (converted to age via
  `ssh-to-age`).
- **User editing key** — `~/.config/sops/age/keys.txt` (mode `600`, persisted under
  `/persist`). `SOPS_AGE_KEY_FILE` is set in the Fish environment, so editing needs no prefix:

```bash
sops edit nixos/host-secrets.yaml      # `sops <file>` alone just prints usage
```

## The two-place rule

!!! danger "Secrets live in exactly two places"
    1. **sops-encrypted** — `nixos/host-secrets.yaml` / `nixos/vm-secrets.yaml` (committable
       because encrypted).
    2. **`/persist`** — never git-tracked.

    They are **never** placed under `dots/`, which is published publicly. As a safety net,
    `.gitignore` excludes `nixos/*.yaml`. Agent credentials (e.g. `~/.gemini`) live in persisted
    `$HOME` directories outside the repo, not under `dots/`.

**Adding a secret:** add it to `nixos/host-secrets.yaml` → declare `sops.secrets.<name>` in
`configuration.nix` → consume it (e.g. export in `home/shell.nix`).
