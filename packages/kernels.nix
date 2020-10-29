{ lib
, stdenv
, python3
, pkgs
, jupyter_generic_kernel
, gccOffloading
, linuxPackages
, cudatoolkit
}:
let
  kernelMaker =
    { targetCompiler
    , targetFlags
    , languageName
    , fileExtension
    , ldPrefix ? ""
    , ldSuffix ? ""
    , name
    , displayName
    , logo
    }:
    let
      pkg = jupyter_generic_kernel {
        inherit targetCompiler targetFlags languageName fileExtension ldPrefix ldSuffix;
      };
      kernelEnv = python3.withPackages (python3Packages:
        [
          (pkg.override { inherit python3Packages; })
        ]
      );

      kernelFile = {
        argv = [
          "${kernelEnv.interpreter}"
          "-m"
          "jupyter_c_kernel" # Not a mistake, we do not bother renaming the python module
          "-f"
          "{connection_file}"
        ];
        display_name = displayName;
        language = lib.strings.toLower languageName;
        logo64 = "logo-64x64.png";
      };

      kernel = stdenv.mkDerivation {
        inherit name;
        phases = "installPhase";
        src = logo;
        buildInputs = [ ];
        installPhase = ''
          mkdir -p $out/kernels/kernel_${name}
          cp $src $out/kernels/kernel_${name}/logo-64x64.png
          echo '${builtins.toJSON kernelFile}' > $out/kernels/kernel_${name}/kernel.json
        '';
      };
    in
    {
      spec = kernel;
      runtimePackages = [ ];
    };


  cpp_openmp_kernel = kernelMaker {
    targetCompiler = "${gccOffloading}/bin/g++";
    targetFlags = [ "-I." "-fPIC" "-shared" "-rdynamic" "-std=c++17" "-fopenmp" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "C++";
    fileExtension = "cpp";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "cpp_openmp";
    displayName = "C++ with OpenMP";
    logo = ../logos/cpp.png;
  };
  cpp_openacc_kernel = kernelMaker {
    targetCompiler = "${gccOffloading}/bin/g++";
    targetFlags = [ "-I." "-fPIC" "-shared" "-rdynamic" "-std=c++17" "-fopenacc" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "C++";
    fileExtension = "cpp";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "cpp_openacc";
    displayName = "C++ with OpenACC";
    logo = ../logos/cpp.png;
  };
  fortran_openmp_kernel = kernelMaker {
    targetCompiler = "${gccOffloading}/bin/gfortran";
    targetFlags = [ "-I." "-fPIC" "-shared" "-rdynamic" "-fopenmp" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "Fortran";
    fileExtension = "f90";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "fortran_openmp";
    displayName = "Fortran with OpenMP";
    logo = ../logos/fortran.png;
  };
  fortran_openacc_kernel = kernelMaker {
    targetCompiler = "${gccOffloading}/bin/gfortran";
    targetFlags = [ "-I." "-fPIC" "-shared" "-rdynamic" "-fopenacc" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "Fortran";
    fileExtension = "f90";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "fortran_openacc";
    displayName = "Fortran with OpenACC";
    logo = ../logos/fortran.png;
  };
  nvcc_kernel = kernelMaker {
    targetCompiler = "${cudatoolkit}/bin/nvcc";
    targetFlags = [ "-I." "--compiler-options" "-fPIC" "-shared" "--compiler-options" "-rdynamic" "-L${cudatoolkit.lib}/lib" ];
    languageName = "Cuda";
    fileExtension = "cu";
    ldPrefix = "${cudatoolkit.lib}/lib";
    name = "cuda";
    displayName = "Cuda compiler";
    logo = ../logos/cuda.png;
  };
in
[ cpp_openmp_kernel cpp_openacc_kernel fortran_openmp_kernel fortran_openacc_kernel nvcc_kernel ]
