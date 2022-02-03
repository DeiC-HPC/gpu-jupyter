{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jupyterWith = { url = "github:TethysSvensson/jupyterWith"; flake = false; };
    nixos-rocm = { url = "github:nixos-rocm/nixos-rocm"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs:
    with (import ./common/inputs.nix inputs);
    import ./common/outputs.nix {
      inherit nixpkgs pkgs jupyterWith system nixos-rocm;
    };
}
