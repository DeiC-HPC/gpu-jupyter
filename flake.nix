{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jupyterWith = { url = "github:tweag/jupyterWith"; flake = false; };
  };

  outputs = { nixpkgs, self, ... }@flakeArgs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      jupyterWith = import flakeArgs.jupyterWith {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            (import "${flakeArgs.jupyterWith}/nix/haskell-overlay.nix")
            (import "${flakeArgs.jupyterWith}/nix/python-overlay.nix")
          ];
        };
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
        jupyter_c_kernel = pkgs.callPackage ./packages/jupyter-c-kernel.nix {
          gccOffload = gcc10Offloading;
        };
        jupyter_cpp_kernel = pkgs.callPackage ./packages/jupyter-cpp-kernel.nix {
          gccOffload = gcc10Offloading;
        };
        jupyter_fortran_kernel = pkgs.callPackage ./packages/jupyter-fortran-kernel.nix {
          gccOffload = gcc10Offloading;
        };
        kernels = pkgs.callPackage ./packages/kernels.nix {
          inherit jupyter_c_kernel jupyter_cpp_kernel jupyter_fortran_kernel;
        };
        jupyter = jupyterWith.jupyterlabWith {
          inherit kernels;
        };
      };
    };
}
