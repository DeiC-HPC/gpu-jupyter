args:

let
  defaultJupyterWithSrc = (builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "35eb565c6d00f3c61ef5e74e7e41870cfa3926f7";
  });
  jupyterWithSrc = args.jupyterWith or defaultJupyterWithSrc;
in rec {
  system = "x86_64-linux";
  nixpkgs = args.nixpkgs or builtins.fetchTarball {
    url = "https://nixos.org/channels/nixos-20.09/nixexprs.tar.xz";
  };
  pkgs = args.pkgs or (import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  });
  jupyterWith = import jupyterWithSrc {
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (import "${jupyterWithSrc}/nix/haskell-overlay.nix")
        (import "${jupyterWithSrc}/nix/python-overlay.nix")
      ];
    };
  };
}
