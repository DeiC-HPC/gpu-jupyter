{ callPackage, stdenv, fetchurl, texinfo, which, gettext, perl, newlib, gmp, mpfr, libmpc, libelf }:

let majorVersion = "10";
    version = "${majorVersion}.2.0";
    nvptxTools = callPackage ./nvptx-tools.nix { };
    newlib = callPackage ./newlib.nix { };
in

stdenv.mkDerivation {
  pname = "gcc";
  inherit version;  

  src = fetchurl {
    url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
    sha256 = "130xdkhmz1bc2kzx061s3sfwk36xah1fw5w332c0nzwwpdl47pdq";
  };

  outputs = [ "out" "man" "info" "lib" ];

  hardeningDisable = [ "format" "pie" ];

  nativeBuildInputs = [ texinfo which gettext perl gmp mpfr libmpc libelf ];

  postPatch = ''
    configureScripts=$(find . -name configure)
    for configureScript in $configureScripts; do
      patchShebangs $configureScript
    done
  '';

  postUnpack = ''
    ln -s ${newlib} gcc-${version}/newlib
  '';

  configurePhase = ''
    mkdir build
    cd build
    ../configure $configureFlags
  '';

  configureFlags = [
    "--target=nvptx-none"
    "--enable-as-accelerator-for=x86_64-pc-linux-gnu"
    "--with-build-time-tools=${nvptxTools}/nvptx-none/bin"
    "--disable-sjlj-exceptions"
    "--enable-newlib-io-long-long"
  ];
}