# Nix daemon settings (Lix from nixpkgs), substituters, GC, and the nixpkgs
# config block.
{
  pkgs,
  username,
  ...
}:
{
  nix = {
    # Lix from nixpkgs (binary-cached, tracks nixpkgs updates). Replaces the
    # lix-project/nixos-module flake input, whose release branches lag behind
    # the lixPackageSets versions nixpkgs keeps around.
    package = pkgs.lixPackageSets.stable.lix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        username
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.lix.systems"
        "https://cuda-maintainers.cachix.org"
        "https://cache.numtide.com"
        "https://attic.xuyh0120.win/lantian"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.lix.systems:aBnZU3F19808R5N0sczBmsWwI5YI+433R9M2iS2Hcy4="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      ];
      min-free = 536870912; # 512MB
      max-free = 1073741824; # 1GB
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
    optimise.automatic = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };
}
