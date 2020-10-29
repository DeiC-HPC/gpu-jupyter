{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    jupyterWith = { url = "github:TethysSvensson/jupyterWith"; flake = false; };
  };

  outputs = inputs:
    with (import ./common/inputs.nix inputs);
    import ./common/outputs.nix {
      inherit nixpkgs pkgs jupyterWith system;
    };
}
