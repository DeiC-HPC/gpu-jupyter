{ nixpkgs
, pkgs
, jupyterWith
}:

let 
  # arguments deliberately left out
  jupyter_generic_kernel = pkgs.callPackage ../packages/jupyter-generic-kernel.nix;
in

rec {
  newlibSource = pkgs.callPackage ../packages/sources/newlib.nix { };
  gcc10-1-source = pkgs.callPackage ../packages/sources/gcc10.1.nix { };
  gcc10-2-source = pkgs.callPackage ../packages/sources/gcc10.2.nix { };
  nvptxTools = pkgs.callPackage ../packages/nvptx-tools.nix { };
  gcc10-1-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
    inherit newlibSource nvptxTools;
    gccSource = gcc10-1-source;
  };
  gcc10-2-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
    inherit newlibSource nvptxTools;
    gccSource = gcc10-2-source;
  };
  gcc10-1-offloading = pkgs.wrapCCWith {
    cc = pkgs.callPackage ../packages/gcc-offloading.nix {
      inherit nixpkgs;
      gccNvptx = gcc10-1-nvptx;
      gccSource = gcc10-1-source;
    };
    extraBuildCommands = ''
      echo '-B ${gcc10-1-nvptx}/bin/ -B ${gcc10-1-nvptx}/libexec/gcc/x86_64-unknown-linux-gnu/10.1.0/' >> $out/nix-support/cc-cflags
    '';
  };
  gcc10-2-offloading = pkgs.wrapCCWith {
    cc = pkgs.callPackage ../packages/gcc-offloading.nix {
      inherit nixpkgs;
      gccNvptx = gcc10-2-nvptx;
      gccSource = gcc10-2-source;
    };
    extraBuildCommands = ''
      echo '-B ${gcc10-2-nvptx}/bin/ -B ${gcc10-2-nvptx}/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/' >> $out/nix-support/cc-cflags
    '';
  };
  kernels = pkgs.callPackage ../packages/kernels.nix {
    inherit jupyter_generic_kernel;
    gccOffloading = gcc10-1-offloading;
  };
  jupyter = pkgs.callPackage ../packages/jupyter.nix {
    jupyter = jupyterWith.jupyterlabWith {
      inherit kernels;
      directory = jupyterWith.mkDirectoryFromLockFile {
        yarnlock = ../packages/jupyter-lockfiles/yarn.lock;
        packagefile = ../packages/jupyter-lockfiles/package.json;
        sha256 = "0d9sxj6l2vzk0ffvaxw0qr0c194q2b7yk0kr93f854naiwqrgm43";
      };
    };
  };
}
