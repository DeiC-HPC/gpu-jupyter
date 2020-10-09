{ callPackage, stdenv, fetchurl, texinfo, which, gettext, perl, gmp, mpfr, libmpc, libelf, glibc, nvptxTools, newlibSource }:

let majorVersion = "10";
    version = "${majorVersion}.2.0";
in

stdenv.mkDerivation {
  pname = "gcc-nvptx";
  inherit version;  

  src = fetchurl {
    url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
    sha256 = "130xdkhmz1bc2kzx061s3sfwk36xah1fw5w332c0nzwwpdl47pdq";
  };

  hardeningDisable = [ "format" "pie" ];

  nativeBuildInputs = [ texinfo which gettext perl gmp mpfr libmpc libelf ];

  postPatch = ''
    configureScripts=$(find . -name configure)
    for configureScript in $configureScripts; do
      patchShebangs $configureScript
    done
  '';

  postUnpack = ''
    ln -s ${newlibSource}/newlib gcc-${version}/newlib
  '';

  configurePhase = ''
    mkdir build
    cd build
    ../configure $configureFlags --prefix=$out
  '';

  configureFlags = [
    "--target=nvptx-none"
    "--enable-as-accelerator-for=x86_64-unknown-linux-gnu"
    "--with-build-time-tools=${nvptxTools}/nvptx-none/bin"
    "--disable-sjlj-exceptions"
    "--enable-newlib-io-long-long"
    "--enable-languages=c,c++,lto"
  ];

  postInstall = ''
    for f in ${nvptxTools}/nvptx-none/bin/*; do
      ln -s $f $out/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0/accel/nvptx-none
    done

    mkdir -p $out/nix-support
    echo "-B$out/libexec/gcc/x86_64-unknown-linux-gnu/10.2.0" > $out/nix-support/cc-cflags
  '';

  dontDisableStatic = true;
  doCheck = false;
}
