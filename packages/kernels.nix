{ stdenv
, python3
, pkgs
, jupyter_c_kernel
, jupyter_cpp_kernel
, jupyter_fortran_kernel
}:

let
  kernelMaker = name: pkg: language: logo:
    let
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
        display_name = name;
        inherit language;
        logo64 = "logo-64x64.png";
      };

      kernel = stdenv.mkDerivation {
        inherit name;
        phases = "installPhase";
        src = logo;
        buildInputs = [];
        installPhase = ''
          mkdir -p $out/kernels/c_${name}
          cp $src $out/kernels/c_${name}/logo-64x64.png
          echo '${builtins.toJSON kernelFile}' > $out/kernels/c_${name}/kernel.json
        '';
      };
    in
      {
        spec = kernel;
        runtimePackages = [];
      };
in
  [
    (kernelMaker "c-kernel" jupyter_c_kernel "c" ./c.png)
    (kernelMaker "cpp-kernel" jupyter_cpp_kernel "c++" ./c.png)
    (kernelMaker "fortran-kernel" jupyter_fortran_kernel "fortran" ./c.png)
  ]
