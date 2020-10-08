{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, self, ... }@flakeArgs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages."${system}" = rec {
        newlibSource = pkgs.callPackage ./newlib.nix { };
        nvptxTools = pkgs.callPackage ./nvptx-tools.nix { };
        gccNvptx = pkgs.callPackage ./gcc-nvptx.nix {
          inherit newlibSource nvptxTools;
        };
        gccTest = pkgs.wrapCC (pkgs.callPackage ./gcc-test.nix {
          inherit nixpkgs gccNvptx;
        });
        foo = pkgs.callPackage ./foo.nix {
          inherit gccTest;
        };
      };
    };
}
