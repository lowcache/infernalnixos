{ pkgs, ... }:
{
  # Portable CLI core. Every entry must have an aarch64-linux build in the
  # binary cache — nix-on-droid builds on the phone, where compiling anything
  # substantial from source is not viable. Host-only tooling (Wayland utils,
  # hardware control, Android forensics, GUI apps) stays in home/pkgs.nix.
  home.packages = with pkgs; [
    # POSIX baseline
    coreutils
    findutils
    diffutils
    gawk
    gnugrep
    gnutar
    gzip
    patch
    moreutils
    openssl

    # Build/runtime toolchains used by scripts and agent tooling.
    # `nodejs` and `go` are deliberately NOT here: at the current nixpkgs rev
    # nodejs has no aarch64 substitute (the phone would compile it from source),
    # and go adds ~300 MB for a toolchain a phone rarely needs. Both stay in
    # home/pkgs.nix; droid/home.nix can opt in explicitly.
    gnumake
    python3

    # Shell + navigation
    fish
    fzf
    eza
    bat
    bat-extras.batgrep
    ripgrep
    fd
    jq
    bc
    tree
    htop
    psmisc
    socat
    direnv

    # Editor + Nix authoring. `pandoc` (micro's `preview` backend) and
    # `ripgrep-all` stay desktop-only — between them they drag in a Haskell
    # toolchain, ffmpeg, poppler and tesseract, which is most of a multi-GB
    # closure for two conveniences.
    micro
    nil
    nixfmt

    # Git + forge
    git
    git-lfs
    lazygit
    gh

    # Secrets
    gnupg
    sops
    ssh-to-age
  ];
}
