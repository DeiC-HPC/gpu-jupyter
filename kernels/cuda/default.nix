{self, system, lib, mkKernel, pkgs, ...}:
let
  inherit (lib) types;
  kernelName = "cuda";
  kernelOptions = {
    config,
    name,
    ...
  }:
  let
    jupyter_generic_kernel = pkgs.callPackage ../../packages/jupyter-generic-kernel.nix;
    buildKernel = {
      self
      , system
      , cudatoolkit
      , name ? "CUDA"
      , displayName ? "CUDA" }:
      let
        res = import ./../../packages/kernelmaker.nix {
          inherit jupyter_generic_kernel name displayName;
          python3 = pkgs.python310;
          targetCompiler = "${cudatoolkit}/bin/nvcc";
          targetFlags = [ "--compiler-options" "-fPIC" "-shared" "-O3" "--compiler-options" "-rdynamic" "-L${cudatoolkit.lib}/lib" "-L${pkgs.gcc-unwrapped.lib}/lib" ];
          languageName = "c++";
          languageVersion = "c++17";
          fileExtension = "cu";
          ldPrefix = "${cudatoolkit.lib}/lib:${pkgs.gcc-unwrapped.lib}/lib";
          logo64 = ./cuda.png;
          includeFlags = [ "--compiler-options" "-idirafter" ];
        };
      in
      res;
  in
  {
    options = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        example = true;
      };
      name = lib.mkOption {
        type = types.str;
        default = "${kernelName}-${name}";
        example = "${kernelName}-example";
        description = lib.mdDoc ''
          Name of the ${kernelName} kernel.
        '';
      };
      displayName = lib.mkOption {
        type = types.str;
        default = "${config.name} kernel";
        example = "${kernelName} example kernel";
        description = lib.mdDoc ''
          Display name of the ${kernelName} kernel.
        '';
      };
      cudatoolkit = lib.mkOption {
        type = types.package;
        description = lib.mdDoc ''
          Cuda version for the kernel.
        '';
      };
      kernelArgs = lib.mkOption {
        type = types.lazyAttrsOf types.raw;
        readOnly = true;
        internal = true;
      };
      build = lib.mkOption {
        type = types.package;
        internal = true;
      };
    };

    config = lib.mkIf config.enable {
      build = mkKernel (buildKernel config.kernelArgs);

      kernelArgs = {
        inherit self system;
        inherit (config) name displayName cudatoolkit;
      };
    };
  };
in {
  options.kernel.${kernelName} = lib.mkOption {
    type = types.attrsOf (types.submodule kernelOptions);
    default = {};
    example = lib.literalExpression ''
      {
        kernel.${kernelName}."example".enable = true;
      }
    '';
    description = lib.mdDoc ''
      A ${kernelName} kernel for IPython.
    '';
  };
}