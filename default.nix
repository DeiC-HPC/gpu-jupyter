{ unused ? null, ... } @ args:

with (import ./common/inputs.nix args);
with (import ./common/outputs.nix {
  inherit nixpkgs pkgs jupyterWith;
});

pkgs.symlinkJoin {
  name = "jupyter";
  paths = [ jupyter gcc10Offloading ];
}
