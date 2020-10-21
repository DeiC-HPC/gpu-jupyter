{ unused ? null, ... } @ args:

with (import ./common/inputs.nix args);
with (import ./common/outputs.nix {
  inherit nixpkgs pkgs jupyterWith;
});

pkgs.mkShell {
  nativeBuildInputs = [ jupyter gcc10Offloading ];
  shellHook = ''
    export NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu=1
    export NIX_HARDENING_ENABLE='fortify stackprotector pic strictoverflow relro bindnow'
  '';
}
