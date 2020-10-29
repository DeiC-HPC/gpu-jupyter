{ unused ? null, ... } @ args:

with (import ./common/inputs.nix args);
with (import ./common/outputs.nix {
  inherit nixpkgs pkgs jupyterWith system;
}).packages."${system}";

pkgs.symlinkJoin {
  name = "hpc-nix";
  paths = [ jupyter gccOffloading ];
}
