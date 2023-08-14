{ jupyter_generic_kernel
, python3
, targetCompiler
, targetFlags
, languageName
, languageVersion
, fileExtension
, includeFlags
, ldPrefix ? ""
, ldSuffix ? ""
, name
, displayName
, logo64
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
in
{
  inherit name displayName logo64;
  language = languageName;
  argv = [
          "${kernelEnv.interpreter}"
          "-m"
          "jupyter_c_kernel" # Not a mistake, we do not bother renaming the python module
          "-f"
          "{connection_file}"
        ];
  codemirrorMode = "clike";
}