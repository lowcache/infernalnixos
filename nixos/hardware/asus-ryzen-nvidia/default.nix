{ config, pkgs, lib, inputs, ... }: {
  imports = [
    ./gpu.nix
    ./kernel.nix
  ];
}
