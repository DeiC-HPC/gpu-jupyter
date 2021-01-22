{ pkgs, fetchurl }:
let
  userEnv = name: runScript: pkgs.buildFHSUserEnv {
    inherit name runScript;
    targetPkgs = pkgs: (with pkgs;
    [
      cudatoolkit
      zlib
    ]);
  };

  installNvhpc = pkgs.writeScript "install-nvhpc" ''
    #!${pkgs.bash}/bin/bash
    export NVHPC_SILENT=true;
    export NVHPC_INSTALL_DIR=$out;
    sed 's@grep include@grep "^\\s*/\\S*include"@' -i ./install_components/Linux_x86_64/20.11/compilers/bin/makelocalrc
    ./install
  '';

  nvhpcInstallation = pkgs.stdenv.mkDerivation rec {
    pname = "nvidia-hpc-sdk";
    version = "20.11";

    phases = [ "unpackPhase" "installPhase" ];

    src = fetchurl {
      url = "https://developer.download.nvidia.com/hpc-sdk/20.11/nvhpc_2020_2011_Linux_x86_64_cuda_11.1.tar.gz";
      sha256 = "0njqsflw59wv0hgdgib1f1f1qn2kvzarcyycm7gzzc5nls55vfpf";
    };

    installEnv = userEnv "installer" ''
      ${installNvhpc}
    '';

    installPhase = ''
      ${installEnv}/bin/${installEnv.name}
    '';
  };
  nvcpp = userEnv "nvc++" "${nvhpcInstallation}/Linux_x86_64/20.11/compilers/bin/nvc++";
  nvfortran = userEnv "nvfortran" "${nvhpcInstallation}/Linux_x86_64/20.11/compilers/bin/nvfortran";
in
  pkgs.symlinkJoin {
    name = "nvidia-hpc-compilers";
    pname = "nvhpc-cc";
    paths = [
      nvcpp
      nvfortran
    ];
  }
