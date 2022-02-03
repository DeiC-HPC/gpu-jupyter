{ nixpkgs
, pkgs
, jupyterWith
, system
, nixos-rocm
}:
let
  # arguments deliberately left out
  jupyter_generic_kernel = pkgs.callPackage ../packages/jupyter-generic-kernel.nix;
in
rec {
  packages."${system}" = rec {
    # COMPILERS
    nvhpc = pkgs.callPackage ../packages/nvhpc.nix { };
    newlibSource = pkgs.callPackage ../packages/sources/newlib.nix { };
    gcc9-3-source = pkgs.callPackage ../packages/sources/gcc9.3.nix { };
    gcc10-1-source = pkgs.callPackage ../packages/sources/gcc10.1.nix { };
    gcc10-2-source = pkgs.callPackage ../packages/sources/gcc10.2.nix { };
    gcc11-2-source = pkgs.callPackage ../packages/sources/gcc11.2.nix { };
    nvptxTools = pkgs.callPackage ../packages/nvptx-tools.nix { };
    amdgcn-amdhsa = pkgs.callPackage ../packages/amdgcn-amdhsa.nix { };
    gcc9-3-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
      inherit newlibSource nvptxTools;
      gccSource = gcc9-3-source;
    };
    gcc10-1-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
      inherit newlibSource nvptxTools;
      gccSource = gcc10-1-source;
    };
    gcc10-2-nvptx = pkgs.callPackage ../packages/gcc-nvptx.nix {
      inherit newlibSource nvptxTools;
      gccSource = gcc10-2-source;
    };
    gcc10-2-amdgcn = pkgs.callPackage ../packages/gcc-amdgcn.nix {
      inherit newlibSource amdgcn-amdhsa;
      gccSource = gcc10-2-source;
    };
    gcc11-2-amdgcn = pkgs.callPackage ../packages/gcc-amdgcn.nix {
      inherit newlibSource amdgcn-amdhsa;
      gccSource = gcc11-2-source;
      fpicPatch = false;
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
    gcc11-2-offloading-amd = pkgs.wrapCCWith {
      cc = pkgs.callPackage ../packages/gcc-offloading.nix {
        inherit nixpkgs;
        gccAmdgcn = gcc11-2-amdgcn;
        gccSource = gcc11-2-source;
        hasNvptx = false;
        fpicPatch = false;
      };
      extraBuildCommands = ''
        echo '-B${gcc11-2-amdgcn}/bin/ -B${gcc11-2-amdgcn}/libexec/gcc/x86_64-unknown-linux-gnu/11.2.0/' >> $out/nix-support/cc-cflags
      '';
    };
    gcc10-2-offloading-amd = pkgs.wrapCCWith {
      cc = pkgs.callPackage ../packages/gcc-offloading.nix {
        inherit nixpkgs;
        gccAmdgcn = gcc10-2-amdgcn;
        gccSource = gcc10-2-source;
        hasNvptx = false;
      };
      extraBuildCommands = ''
        echo '-B${gcc10-2-amdgcn}/bin/ -B${gcc10-2-amdgcn}/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/' >> $out/nix-support/cc-cflags
      '';
    };
    gccOffloading = gcc10-2-offloading-amd;
    hip = pkgs.hip;
    rocm-openmp = pkgs.rocm-openmp;

    # JUPYTER
    kernels = pkgs.callPackage ../packages/kernels.nix {
      inherit jupyter_generic_kernel gccOffloading nvhpc;
      rocm-llvm = pkgs.llvmPackages_rocm.clang;
      rocm-device-libs = pkgs.rocm-device-libs;
      hipcc = pkgs.hip;
    };

    cudaSearch = pkgs.callPackage ../packages/cuda-search.nix { };
    patchedPyOpenCL12 = pkgs.python3Packages.pyopencl.overrideAttrs (attrs: {
      postPatch = attrs.postPatch + "\necho 'CL_PRETEND_VERSION = \"1.2\"' >> siteconf.py";
    });
    jupyter = pkgs.callPackage ../packages/jupyter.nix {
      inherit cudaSearch;
      jupyter = jupyterWith.jupyterlabWith {
        inherit kernels;
        directory = jupyterWith.mkDirectoryFromLockFile {
          yarnlock = ../packages/jupyter-lockfiles/yarn.lock;
          packagefile = ../packages/jupyter-lockfiles/package.json;
          sha256 = "0d9sxj6l2vzk0ffvaxw0qr0c194q2b7yk0kr93f854naiwqrgm43";
        };
        extraJupyterPath = p: with p.python3Packages; makePythonPath [ numpy pycuda patchedPyOpenCL12 matplotlib scipy pillow ];
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

    # IMAGES
    docker-image = pkgs.dockerTools.buildImage {
      fromImage = cudaFromDockerHub;
      name = "jupyter-gcc-offloading";
      config.cmd = ["${startScript}"];
    };
    singularity-tools = pkgs.callPackage ../packages/singularity-tools.nix { util-linux = pkgs.util-linux ; };
    singularity-image = singularity-tools.buildImage {
      name = "jupyter-gcc-offloading-singularity";
      runScript = "${startScript}";
      diskSize = 100000;
      memSize = 50000;
    };
  };
  devShell."${system}" =
    with packages."${system}";
    pkgs.callPackage ../packages/devshell.nix {
      inherit jupyter gccOffloading cudaSearch nvhpc;
      rocm-llvm = pkgs.llvmPackages_rocm.clang;
    };
}
