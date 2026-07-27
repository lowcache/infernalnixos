---
date: 2026-07-24
authors:
  - lowcache
categories:
  - NixOS
  - Impermanence
tags:
  - impermanence
  - systemd
  - home-manager
---

# The impermanence bind-mount symlink trap

Moving a directory into the persistence list on an impermanent NixOS host looks trivial
until `nixos-rebuild switch` dies with:

```
home-lowcache-.gemini.mount: Mount path /home/lowcache/.gemini is not canonical (contains a symlink).
```

Here is why it happens, and the one rule that avoids it.

<!-- more -->

## The setup

On this host, root is a tmpfs that is wiped every boot; anything that must survive lives on
`/persist` and is surfaced back into `$HOME` by [impermanence](../../architecture/impermanence.md).
The mechanism is a **systemd bind mount** per persisted directory: the real data lives at
`/persist/home/lowcache/<dir>` (the mount *source*), and systemd bind-mounts it onto
`~/<dir>` (the mount *target*) at activation.

Adding a directory is a one-line change to the persistence list:

```nix
home.persistence."/persist".directories = [
  # ...
  ".gemini"
];
```

## The trap

I was migrating `~/.gemini` from an old repo symlink to a real persisted directory. To avoid a
dangling link in the window between moving the data and rebuilding, I "helpfully" pre-created a
bridge symlink:

```bash
ln -sfn /persist/home/lowcache/.gemini ~/.gemini   # <- the mistake
```

That is exactly what breaks the mount. **systemd refuses to bind-mount onto a path whose target
contains a symlink** — the target must be *canonical*. Every other persisted directory works
because its `~/<dir>` is a plain, empty directory that the bind mount covers. The symlink made
`.gemini` the odd one out.

The failure is also self-obscuring: a partial activation keeps re-creating the (empty) mount
source, so it never looks resolved, and the data you moved sits stranded in whatever you renamed
it to.

## The rule

For bind-mount persistence, the target is always a **real, empty directory** — never a symlink.
Let the data live at the source and let systemd do the mounting:

```bash
# target: a canonical empty mountpoint (NOT a symlink)
rm -f ~/.gemini
mkdir -p ~/.gemini

# source: the actual data, on /persist
mv /persist/home/lowcache/.geminibak /persist/home/lowcache/.gemini
```

Then `nixos-rebuild switch` mounts source onto target cleanly. Verify with `ls ~/.gemini` (data
shows through the mount) and `findmnt ~/.gemini`.

The general lesson: symlink bridges are a reflex from `mkOutOfStoreSymlink`-style persistence,
where `~/<dir>` *is* a symlink by design. Under bind-mount persistence the model is inverted — the
target must stay canonical. Know which of the two your host uses before you reach for `ln -s`.
