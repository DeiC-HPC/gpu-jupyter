{ callPackage, stdenv, fetchurl, texinfo, which, gettext, perl, newlib, gmp, mpfr, libmpc, libelf, glibc, cudatoolkit_11 }:

let majorVersion = "10";
    version = "${majorVersion}.2.0";
    gccNvptx = callPackage ./gcc-nvptx.nix { };
in

stdenv.mkDerivation {
  pname = "gcc";
  inherit version;  

  src = fetchurl {
    url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
    sha256 = "130xdkhmz1bc2kzx061s3sfwk36xah1fw5w332c0nzwwpdl47pdq";
  };

  hardeningDisable = [ "format" "pie" ];

  nativeBuildInputs = [ texinfo which gettext perl gmp mpfr libmpc libelf gccNvptx ];

  postPatch = ''
    configureScripts=$(find . -name configure)
    for configureScript in $configureScripts; do
      patchShebangs $configureScript
    done

    sed -i \
      -e "s,glibc_header_dir=/usr/include,glibc_header_dir=${stdenv.cc.libc_dev}/include", \
      gcc/configure
  '';

  configurePhase = ''
    mkdir build
    cd build
    ../configure $configureFlags --prefix=$out
  '';

  configureFlags = [
    "--build=x86_64-pc-linux-gnu"
    "--host=x86_64-pc-linux-gnu"
    "--target=x86_64-pc-linux-gnu"
    "--disable-multilib"
    "--enable-offload-targets=nvptx-none=${gccNvptx}/nvptx-none"
    "--with-cuda-driver=${cudatoolkit_11}"
  ];  

  dontDisableStatic = true;
  doCheck = false;
}
