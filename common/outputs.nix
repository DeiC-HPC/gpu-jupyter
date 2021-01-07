{ nixpkgs
, pkgs
, jupyterWith
, system
}:
let
  # arguments deliberately left out
  jupyter_generic_kernel = pkgs.callPackage ../packages/jupyter-generic-kernel.nix;
in
rec {
  packages."${system}" = rec {
    newlibSource = pkgs.callPackage ../packages/sources/newlib.nix { };
    gcc9-3-source = pkgs.callPackage ../packages/sources/gcc9.3.nix { };
    gcc10-1-source = pkgs.callPackage ../packages/sources/gcc10.1.nix { };
    gcc10-2-source = pkgs.callPackage ../packages/sources/gcc10.2.nix { };
    nvptxTools = pkgs.callPackage ../packages/nvptx-tools.nix { };
    gcc9-3-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
      inherit newlibSource nvptxTools;
      gccSource = gcc9-3-source;
      hasGcn = false;
    };
    gcc10-1-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
      inherit newlibSource nvptxTools;
      gccSource = gcc10-1-source;
    };
    gcc10-2-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
      inherit newlibSource nvptxTools;
      gccSource = gcc10-2-source;
    };
    gcc9-3-offloading = pkgs.wrapCCWith {
      cc = pkgs.callPackage ../packages/gcc-offloading.nix {
        inherit nixpkgs;
        gccNvptx = gcc9-3-nvptx;
        gccSource = gcc9-3-source;
        hasGcn = false;
      };
      extraBuildCommands = ''
        echo '-B ${gcc9-3-nvptx}/bin/ -B ${gcc9-3-nvptx}/libexec/gcc/x86_64-unknown-linux-gnu/9.3.0/' >> $out/nix-support/cc-cflags
      '';
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
    gccOffloading = gcc9-3-offloading;
    kernels = pkgs.callPackage ../packages/kernels.nix {
      inherit jupyter_generic_kernel gccOffloading;
    };
    cudaSearch = pkgs.callPackage ../packages/cuda-search.nix { };
    jupyter = pkgs.callPackage ../packages/jupyter.nix {
      inherit cudaSearch;
      jupyter = jupyterWith.jupyterlabWith {
        inherit kernels;
        directory = jupyterWith.mkDirectoryFromLockFile {
          yarnlock = ../packages/jupyter-lockfiles/yarn.lock;
          packagefile = ../packages/jupyter-lockfiles/package.json;
          sha256 = "0d9sxj6l2vzk0ffvaxw0qr0c194q2b7yk0kr93f854naiwqrgm43";
        };
        extraJupyterPath = p: with p.python3Packages; makePythonPath [ numpy pycuda pyopencl ];
      };
    };
    cudaFromDockerHub = pkgs.dockerTools.pullImage {
      imageName = "nvidia/cuda";
      imageDigest = "sha256:91eaef4d5a8d8a54704d5ccce99904d7ad693e28e6736e839062f1f9a8379249";
      sha256 = "sha256-GmsqcckNMU/bZ2wXmbEfNoLA8+OGQoVEgS7PZFTUGVs=";
    };
    startScript = pkgs.writeScript "start" ''
        #!${pkgs.bash}/bin/sh
        ${jupyter}/bin/jupyter-lab --ip=0.0.0.0 --allow-root
      '';
    docker-image = pkgs.dockerTools.buildImage {
      fromImage = cudaFromDockerHub;
      name = "jupyter-gcc-offloading";
      config.cmd = ["${startScript}"];
    };
    singularity-tools = pkgs.callPackage ../packages/singularity-tools.nix { util-linux = pkgs.util-linux ; };
    singularity-image = singularity-tools.buildImage {
      name = "jupyter-gcc-offloading-singularity";
      runScript = "${startScript}";
      diskSize = 20000;
      memSize = 10000;
    };
  };
  devShell."${system}" = 
    with packages."${system}"; 
    pkgs.callPackage ../packages/devshell.nix {
      inherit jupyter gccOffloading cudaSearch;
    };
}
