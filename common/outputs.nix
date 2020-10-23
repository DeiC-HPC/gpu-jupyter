{ nixpkgs
, pkgs
, jupyterWith
}:

let 
  # arguments deliberately left out
  jupyter_generic_kernel = pkgs.callPackage ../packages/jupyter-generic-kernel.nix;
in

rec {
  newlibSource = pkgs.callPackage ../sources/newlib.nix { };
  gcc10Source = pkgs.callPackage ../sources/gcc10.nix { };
  nvptxTools = pkgs.callPackage ../packages/nvptx-tools.nix { };
  gcc10Nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
    inherit newlibSource nvptxTools;
    gccSource = gcc10Source;
  };
  gcc10Offloading = pkgs.wrapCCWith {
    cc = pkgs.callPackage ../packages/gcc-offloading.nix {
      inherit nixpkgs;
      gccNvptx = gcc10Nvptx;
      gccSource = gcc10Source;
    };
    extraBuildCommands = ''
      echo '-B ${gcc10Nvptx}/bin/ -B ${gcc10Nvptx}/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/' >> $out/nix-support/cc-cflags
    '';
  };
  kernels = pkgs.callPackage ../packages/kernels.nix {
    inherit gcc10Offloading jupyter_generic_kernel;
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
