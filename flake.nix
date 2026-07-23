{
  description = "GPU Learning Jupyter";

  #nixConfig.extra-substituters = [
  #  "https://tweag-jupyter.cachix.org"
  #];
  #nixConfig.extra-trusted-public-keys = [
  #  "tweag-jupyter.cachix.org-1:UtNH4Zs6hVUFpFBTLaA4ejYavPo5EFFqgd7G7FxGW9g="
  #];
  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jupyenv = {
      url = "github:tweag/jupyenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-compat,
    flake-utils,
    nixpkgs,
    jupyenv,
    ...
  } @ inputs:
    flake-utils.lib.eachSystem
    [
      flake-utils.lib.system.x86_64-linux
    ]
    (
      system: let
        inherit (jupyenv.lib.${system}) mkJupyterlabNew mkKernel;

        pkgs = (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });

        singularity-tools = pkgs.singularity-tools;

        # COMPILERS
        #nvhpc = pkgs.callPackage ./packages/nvhpc.nix { };
        #newlibSource = pkgs.callPackage ./packages/sources/newlib.nix { };
        #gcc9-3-source = pkgs.callPackage ./packages/sources/gcc9.3.nix { };
        #gcc10-1-source = pkgs.callPackage ./packages/sources/gcc10.1.nix { };
        #gcc10-2-source = pkgs.callPackage ./packages/sources/gcc10.2.nix { };
        #gcc11-2-source = pkgs.callPackage ./packages/sources/gcc11.2.nix { };
        #nvptxTools = pkgs.callPackage ./packages/nvptx-tools.nix { };
        #amdgcn-amdhsa = pkgs.callPackage ./packages/amdgcn-amdhsa.nix { };
        #gcc9-3-nvptx = pkgs.callPackage ./packages/gcc-nvptx.nix {
        #  inherit newlibSource nvptxTools;
        #  gccSource = gcc9-3-source;
        #};
        #gcc10-1-nvptx = pkgs.callPackage ./packages/gcc-nvptx.nix {
        #  inherit newlibSource nvptxTools;
        #  gccSource = gcc10-1-source;
        #};
        #gcc10-2-nvptx = pkgs.callPackage ./packages/gcc-nvptx.nix {
        #  inherit newlibSource nvptxTools;
        #  gccSource = gcc10-2-source;
        #};
        #gcc10-2-amdgcn = pkgs.callPackage ./packages/gcc-amdgcn.nix {
        #  inherit newlibSource amdgcn-amdhsa;
        #  gccSource = gcc10-2-source;
        #};
        #gcc11-2-amdgcn = pkgs.callPackage ./packages/gcc-amdgcn.nix {
        #  inherit newlibSource amdgcn-amdhsa;
        #  gccSource = gcc11-2-source;
        #  fpicPatch = false;
        #};
        #gcc10-1-offloading = pkgs.wrapCCWith {
        #  cc = pkgs.callPackage ./packages/gcc-offloading.nix {
        #    inherit nixpkgs;
        #    gccNvptx = gcc10-1-nvptx;
        #    gccSource = gcc10-1-source;
        #  };
        #  extraBuildCommands = ''
        #    echo '-B ${gcc10-1-nvptx}/bin/ -B ${gcc10-1-nvptx}/libexec/gcc/x86_64-unknown-linux-gnu/10.1.0/' >> $out/nix-support/cc-cflags
        #  '';
        #};
        #gcc10-2-offloading = pkgs.wrapCCWith {
        #  cc = pkgs.callPackage ./packages/gcc-offloading.nix {
        #    inherit nixpkgs;
        #    gccNvptx = gcc10-2-nvptx;
        #    gccSource = gcc10-2-source;
        #  };
        #  extraBuildCommands = ''
        #    echo '-B ${gcc10-2-nvptx}/bin/ -B ${gcc10-2-nvptx}/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/' >> $out/nix-support/cc-cflags
        #  '';
        #};
        #gcc11-2-offloading-amd = pkgs.wrapCCWith {
        #  cc = pkgs.callPackage ./packages/gcc-offloading.nix {
        #    inherit nixpkgs;
        #    gccAmdgcn = gcc11-2-amdgcn;
        #    gccSource = gcc11-2-source;
        #    hasNvptx = false;
        #    fpicPatch = false;
        #  };
        #  extraBuildCommands = ''
        #    echo '-B${gcc11-2-amdgcn}/bin/ -B${gcc11-2-amdgcn}/libexec/gcc/x86_64-unknown-linux-gnu/11.2.0/' >> $out/nix-support/cc-cflags
        #  '';
        #};
        #gcc10-2-offloading-amd = pkgs.wrapCCWith {
        #  cc = pkgs.callPackage ./packages/gcc-offloading.nix {
        #    inherit nixpkgs;
        #    gccAmdgcn = gcc10-2-amdgcn;
        #    gccSource = gcc10-2-source;
        #    hasNvptx = false;
        #  };
        #  extraBuildCommands = ''
        #    echo '-B${gcc10-2-amdgcn}/bin/ -B${gcc10-2-amdgcn}/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/' >> $out/nix-support/cc-cflags
        #  '';
        #};
        #gccOffloading = gcc10-2-offloading-amd;
        #hip = pkgs.hip;
        #rocm-openmp = pkgs.rocm-openmp;
        #kernels = pkgs.callPackage ./packages/kernels.nix {
        #  inherit jupyter_generic_kernel gccOffloading nvhpc mkKernel;
        #  rocm-llvm = pkgs.llvmPackages_rocm.clang;
        #  rocm-device-libs = pkgs.rocm-device-libs;
        #  hipcc = pkgs.hip;
        #};
        # Cuda hack
        cudaSearch = pkgs.callPackage ./packages/cuda-search.nix { };

        python = pkgs.python312.override {
          packageOverrides = self: super: {
            jaxlib = pkgs.python312Packages.callPackage ./packages/jaxlib-rocm.nix {
              cython = super.cython;
              absl-py = super.absl-py;
              flatbuffers = super.flatbuffers;
              numpy = super.numpy;
              pybind11 = super.pybind11;
              scipy = super.scipy;
              setuptools = super.setuptools;
              six = super.six;
              wheel = super.wheel;

              rocmSupport = true;
              mklSupport = true;
            };

            jax = super.jax.override {
              inherit (self) jaxlib;
            };
          };
        };
        # jaxlib = python.pkgs.jaxlib;
        # jax = python.pkgs.jax;

        # Jupyter
        #jupyter_generic_kernel = pkgs.callPackage ../packages/jupyter-generic-kernel.nix;
        kernels = {...}: {
          kernel.python.gpu = {
            enable = true;
            python = python;

            extraPackages = ps: [
              ps.numpy
              ps.matplotlib
              # ps.jax
              # ps.jaxlib
            ];
          };
          kernel.c.test.enable = true;
          kernel.hip.gpu.enable = true;
          kernel.cuda.gpu = {
            enable = true;
            cudatoolkit = pkgs.cudatoolkit;
          };
        };

        jupyterlab = mkJupyterlabNew ({...}: {
          imports = [ ./kernels (kernels) ];
        });

      in rec {
        packages = rec {
          inherit jupyterlab;# jax jaxlib;
          startScript = pkgs.writeScript "start" ''
            #!${pkgs.bash}/bin/sh
            set -e

            export NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu=1
            export NIX_HARDENING_ENABLE=fortify stackprotector pic strictoverflow relro bindnow
            source ${cudaSearch}
            ${jupyterlab}/bin/jupyter-lab --ip=0.0.0.0 --allow-root --no-browser
          '';
          singularity-image = singularity-tools.buildImage {
            name = "Jupyter-GPU-singularity";
            runScript = "${startScript}";
            diskSize = 100000;
            memSize = 50000;
          };
	      };

        lib = rec {
          inherit mkKernel;
        };
        packages.default = singularity-image;
        #apps.default.program = "${jupyterlab}/bin/jupyter-lab";
        #apps.default.type = "app";
      }
    );
}
