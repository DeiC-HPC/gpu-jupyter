args:
let
  defaultJupyterWithSrc = (builtins.fetchGit {
    url = https://github.com/TethysSvensson/jupyterWith;
    rev = "daad81179fc8b58ea7f4ab036ba0a4db0fdfdf57";
  });
  jupyterWithSrc = args.jupyterWith or defaultJupyterWithSrc;
in
rec {
  system = "x86_64-linux";
  defaultNixpkgs = builtins.fetchTarball {
    url = "https://nixos.org/channels/nixos-20.09/nixexprs.tar.xz";
  };
  nixpkgs = args.nixpkgs or defaultNixpkgs;
  pkgs = args.pkgs or (import nixpkgs {
    inherit system;
    config.allowUnfree = true;
    config.rocmTargets = ["gfx900" "gfx906" "gfx908" "gfx909" "gfx90a" "gfx1030" "gfx1031" ];
    overlays = [
      (import "${jupyterWithSrc}/nix/python-overlay.nix")
      (import "${jupyterWithSrc}/nix/overlay.nix")
      (import args.nixos-rocm)
    ];
  });
  jupyterWith = import jupyterWithSrc { inherit pkgs; };
}
