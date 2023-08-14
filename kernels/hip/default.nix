{self, system, lib, mkKernel, pkgs, ...}:
let
  inherit (lib) types;
  kernelName = "hip";
  kernelOptions = {
    config,
    name,
    ...
  }:
  let
    jupyter_generic_kernel = pkgs.callPackage ../../packages/jupyter-generic-kernel.nix;
    hipcc = pkgs.hip;
    buildKernel = {
      self
      , system
      , name ? "HIP"
      , displayName ? "HIP" }:
      let
        res = import ./../../packages/kernelmaker.nix {
          inherit jupyter_generic_kernel name displayName;
          python3 = pkgs.python310;
          targetCompiler = "${hipcc}/bin/hipcc";
          targetFlags = [ "-fPIC" "-shared" "-O3" "-rdynamic" "-L${pkgs.gcc-unwrapped.lib}" "-L${pkgs.zlib}/lib" "-L${pkgs.ncurses5}/lib" "-L${pkgs.libdrm}/lib" ];
          languageName = "c++";
          languageVersion = "c++17";
          fileExtension = "cpp";
          ldPrefix = "${pkgs.gcc-unwrapped.lib}/lib:${pkgs.zlib}/lib:${pkgs.ncurses5}/lib:${pkgs.libdrm}/lib";
          logo64 = ./logo64.png;
          includeFlags = [ "-idirafter" ];
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
        description = lib.mdDoc ''
          Enable ${kernelName} kernel.
        '';
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
        inherit (config) name displayName;
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