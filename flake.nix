{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jupyterWith = { url = "github:tweag/jupyterWith"; flake = false; };
  };

  outputs = inputs:
    with (import ./common/inputs.nix inputs);
    {
      packages."${system}" = import ./common/outputs.nix {
        inherit nixpkgs pkgs jupyterWith;
      };
    };
}
