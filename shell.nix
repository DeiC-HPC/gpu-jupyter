{ unused ? null, ... } @ args:

with (import ./common/inputs.nix args);
with (import ./common/outputs.nix {
  inherit nixpkgs pkgs jupyterWith;
});

pkgs.mkShell {
  nativeBuildInputs = [ jupyter gcc10Offloading ];
}
