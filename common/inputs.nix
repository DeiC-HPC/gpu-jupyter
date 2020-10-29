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
    overlays = [
      (import "${jupyterWithSrc}/nix/python-overlay.nix")
      (import "${jupyterWithSrc}/nix/overlay.nix")
    ];
  });
  jupyterWith = import jupyterWithSrc { inherit pkgs; };
}
