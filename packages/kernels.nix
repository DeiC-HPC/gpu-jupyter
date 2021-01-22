{ lib
, stdenv
, python3
, pkgs
, jupyter_generic_kernel
, gccOffloading
, linuxPackages
, cudatoolkit
, nvhpc
}:
let
  kernelMaker =
    { targetCompiler
    , targetFlags
    , languageName
    , languageVersion
    , fileExtension
    , includeFlags
    , ldPrefix ? ""
    , ldSuffix ? ""
    , name
    , displayName
    , logo
    }:
    let
      pkg = jupyter_generic_kernel {
        inherit targetCompiler targetFlags displayName languageName languageVersion fileExtension includeFlags ldPrefix ldSuffix;
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
        language = languageName;
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
    targetFlags = [ "-fPIC" "-shared" "-rdynamic" "-std=c++17" "-O3" "-fopenmp" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "c++";
    languageVersion = "c++17";
    fileExtension = "cpp";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "cpp_openmp";
    displayName = "C++ with OpenMP";
    logo = ../logos/cpp.png;
    includeFlags = [ "-idirafter" ];
  };
  cpp_openacc_kernel = kernelMaker {
    targetCompiler = "${gccOffloading}/bin/g++";
    targetFlags = [ "-fPIC" "-shared" "-rdynamic" "-std=c++17" "-O3" "-fopenacc" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "c++";
    languageVersion = "c++17";
    fileExtension = "cpp";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "cpp_openacc";
    displayName = "C++ with OpenACC";
    logo = ../logos/cpp.png;
    includeFlags = [ "-idirafter" ];
  };
  fortran_openmp_kernel = kernelMaker {
    targetCompiler = "${gccOffloading}/bin/gfortran";
    targetFlags = [ "-fPIC" "-shared" "-rdynamic" "-Ofast" "-fopenmp" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "fortran";
    languageVersion = "F90";
    fileExtension = "f90";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "fortran_openmp";
    displayName = "Fortran with OpenMP";
    logo = ../logos/fortran.png;
    includeFlags = [ "-idirafter" ];
  };
  fortran_openacc_kernel = kernelMaker {
    targetCompiler = "${gccOffloading}/bin/gfortran";
    targetFlags = [ "-fPIC" "-shared" "-rdynamic" "-Ofast" "-fopenacc" "-fno-stack-protector" "-foffload=-lm" "-foffload=-misa=sm_35" ];
    languageName = "fortran";
    languageVersion = "F90";
    fileExtension = "f90";
    ldPrefix = "${gccOffloading.cc}/lib";
    name = "fortran_openacc";
    displayName = "Fortran with OpenACC";
    logo = ../logos/fortran.png;
    includeFlags = [ "-idirafter" ];
  };
  nvcc_kernel = kernelMaker {
    targetCompiler = "${cudatoolkit}/bin/nvcc";
    targetFlags = [ "--compiler-options" "-fPIC" "-shared" "-O3" "--compiler-options" "-rdynamic" "-L${cudatoolkit.lib}/lib" ];
    languageName = "c++";
    languageVersion = "c++17";
    fileExtension = "cu";
    ldPrefix = "${cudatoolkit.lib}/lib";
    name = "cuda";
    displayName = "Cuda compiler";
    logo = ../logos/cuda.png;
    includeFlags = [ "--compiler-options" "-idirafter" ];
  };
  nvcpp_openmp_kernel = kernelMaker {
    targetCompiler = "${nvhpc}/bin/nvc++";
    targetFlags = [ "-shared" "-rdynamic" "-O4" "-mp=gpu" "-rpath" "${pkgs.gcc-unwrapped.lib}/lib" ];
    languageName = "c++";
    languageVersion = "c++17";
    fileExtension = "cpp";
    ldPrefix = "";
    name = "nvcpp-openmp";
    displayName = "NVIDIA HPC SDK nvc++ gpu enabled openmp compiler";
    logo = ../logos/cpp.png;
    includeFlags = [ "-I" ];
  };
  nvcpp_openacc_kernel = kernelMaker {
    targetCompiler = "${nvhpc}/bin/nvc++";
    targetFlags = [ "-shared" "-rdynamic" "-O4" "-acc=gpu" "-rpath" "${pkgs.gcc-unwrapped.lib}/lib" ];
    languageName = "c++";
    languageVersion = "c++17";
    fileExtension = "cpp";
    ldPrefix = "";
    name = "nvcpp-openacc";
    displayName = "NVIDIA HPC SDK nvc++ gpu enabled openacc compiler";
    logo = ../logos/cpp.png;
    includeFlags = [ "-I" ];
  };
  nvfortran_openmp_kernel = kernelMaker {
    targetCompiler = "${nvhpc}/bin/nvfortran";
    targetFlags = [ "-shared" "-O4" "-mp=gpu" "-rpath" "${pkgs.gcc-unwrapped.lib}/lib" ];
    languageName = "fortran";
    languageVersion = "F90";
    fileExtension = "f90";
    ldPrefix = "";
    name = "nvfortran-openmp";
    displayName = "NVIDIA HPC SDK nvfortran gpu enabled openmp compiler";
    logo = ../logos/fortran.png;
    includeFlags = [ "-I" ];
  };
  nvfortran_openacc_kernel = kernelMaker {
    targetCompiler = "${nvhpc}/bin/nvfortran";
    targetFlags = [ "-shared" "-O4" "-acc=gpu" "-rpath" "${pkgs.gcc-unwrapped.lib}/lib" ];
    languageName = "fortran";
    languageVersion = "F90";
    fileExtension = "f90";
    ldPrefix = "";
    name = "nvfortran-openacc";
    displayName = "NVIDIA HPC SDK nvfortran gpu enabled openacc compiler";
    logo = ../logos/fortran.png;
    includeFlags = [ "-I" ];
  };
in
[ cpp_openmp_kernel cpp_openacc_kernel fortran_openmp_kernel fortran_openacc_kernel nvcc_kernel nvcpp_openmp_kernel nvcpp_openacc_kernel nvfortran_openmp_kernel nvfortran_openacc_kernel ]
