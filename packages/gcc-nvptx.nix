{ callPackage
, stdenv
, texinfo
, which
, gettext
, perl
, gmp
, mpfr
, libmpc
, libelf
, gccSource
, newlibSource
, nvptxTools
}:
let inherit (gccSource) version;
in
stdenv.mkDerivation {
  pname = "gcc${version}-nvptx";
  inherit version;

  src = gccSource;

  hardeningDisable = [ "format" "pie" ];

  nativeBuildInputs = [ texinfo which gettext perl gmp mpfr libmpc libelf ];

  patches = [ ./sources/gcn-nvptx-offloading-mkoffload-handle--fpic--fPIC.diff ];

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
    "--disable-bootstrap"
    "--target=nvptx-none"
    "--enable-as-accelerator-for=x86_64-unknown-linux-gnu"
    "--with-build-time-tools=${nvptxTools}/nvptx-none/bin"
    "--disable-sjlj-exceptions"
    "--enable-newlib-io-long-long"
    "--enable-languages=c,c++,fortran,lto"
  ];

  postInstall = ''
    for f in ${nvptxTools}/nvptx-none/bin/*; do
      ln -s $f $out/libexec/gcc/x86_64-unknown-linux-gnu/${version}/accel/nvptx-none
    done

    mkdir -p $out/nix-support
    echo "-B$out/libexec/gcc/x86_64-unknown-linux-gnu/${version}" > $out/nix-support/cc-cflags
  '';

  dontDisableStatic = true;
  doCheck = false;
}
