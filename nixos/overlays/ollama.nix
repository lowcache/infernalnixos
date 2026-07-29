# ollama-cuda 0.32.3 fails to build on nixpkgs 624af665: the setup-cuda-hook
# exports CUDAToolkit_ROOT as a ;-joined list of the cuda *libraries* seen
# (cudart/cublas/cccl — no cuda_nvcc), and the llama.cpp ExternalProject
# configure step (new in the b10091 pin) trusts that env var, finds no nvcc in
# it, and aborts with "CUDA Toolkit not found". Pin ollama-cuda to the
# pre-update nixpkgs rev whose 0.31.1 build is already realized in the store.
# Remove once nixpkgs unstable ships an ollama-cuda that builds again (test
# with: nix build .#nixosConfigurations.volnix.pkgs.ollama-cuda --dry-run
# after dropping this overlay).
_final: prev:
let
  pinned =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/d407951447dcd00442e97087bf374aad70c04cea.tar.gz";
        sha256 = "sha256-8i/87eeoqiGE4yOTjwSA3Eh/ziJRQEmd/unYU+K27sk=";
      })
      {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
in
{
  inherit (pinned) ollama-cuda;
}
