{ unused ? null, ... } @ args:

with (import ./common/inputs.nix args);
with (import ./common/outputs.nix {
  inherit nixpkgs pkgs jupyterWith;
});

pkgs.symlinkJoin {
  inputs = [ jupyter gcc10Offloading ];
}
