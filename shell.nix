{ unused ? null, ... } @ args:

with (import ./common/inputs.nix args);

(import ./common/outputs.nix {
  inherit nixpkgs pkgs jupyterWith system;
}).devShell."${system}"