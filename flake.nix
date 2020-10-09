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
        gccTest = pkgs.wrapCCWith {
          cc = pkgs.callPackage ./gcc-test.nix {
            inherit nixpkgs gccNvptx;
          };
          extraBuildCommands = ''
            echo '-B ${gccNvptx}/bin/ -B ${gccNvptx}/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/' >> $out/nix-support/cc-cflags
          '';
        };
        foo = pkgs.callPackage ./foo.nix {
          inherit gccTest;
        };
      };
    };
}
