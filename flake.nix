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
        newlibSource = pkgs.callPackage ./sources/newlib.nix { };
        gcc10Source = pkgs.callPackage ./sources/gcc10.nix { };
        nvptxTools = pkgs.callPackage ./packages/nvptx-tools.nix { };
        gcc10Nvptx = pkgs.callPackage ./packages/gcc-nvptx.nix {
          inherit newlibSource nvptxTools;
          gccSource = gcc10Source;
        };
        gcc10Offloading = pkgs.wrapCCWith {
          cc = pkgs.callPackage ./packages/gcc-offloading.nix {
            inherit nixpkgs;
            gccNvptx = gcc10Nvptx;
            gccSource = gcc10Source;
          };
          extraBuildCommands = ''
            echo '-B ${gcc10Nvptx}/bin/ -B ${gcc10Nvptx}/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/' >> $out/nix-support/cc-cflags
          '';
        };
      };
    };
}
