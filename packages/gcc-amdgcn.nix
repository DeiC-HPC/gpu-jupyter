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
, amdgcn-amdhsa
, file
, zlib
, fpicPatch ? true
}:

with stdenv.lib;
let inherit (gccSource) version;
in
stdenv.mkDerivation {
  pname = "gcc${version}-amdgcn";
  inherit version;

  src = gccSource;

  enableParallelBuilding = true;
  hardeningDisable = [ "format" "pie" ];

  nativeBuildInputs = [ texinfo which gettext perl gmp mpfr libmpc libelf file zlib ];

  patches =
    (optional fpicPatch ./sources/mkoffload-gcn-fpic.patch);

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
    "--target=amdgcn-amdhsa"
    "--enable-as-accelerator-for=x86_64-unknown-linux-gnu"
    "--with-build-time-tools=${amdgcn-amdhsa}/bin"
    "--disable-sjlj-exceptions"
    "--with-newlib"
    "--enable-languages=c,c++,fortran,lto"
    "--disable-libquadmath"
  ];

  postInstall = ''
    cp -a ${amdgcn-amdhsa}/bin/llvm-ar $out/libexec/gcc/x86_64-unknown-linux-gnu/${version}/accel/amdgcn-amdhsa/ar
    cp -a ${amdgcn-amdhsa}/bin/llvm-ar $out/libexec/gcc/x86_64-unknown-linux-gnu/${version}/accel/amdgcn-amdhsa/ranlib
    cp -a ${amdgcn-amdhsa}/bin/llvm-mc $out/libexec/gcc/x86_64-unknown-linux-gnu/${version}/accel/amdgcn-amdhsa/as
    cp -a ${amdgcn-amdhsa}/bin/llvm-nm $out/libexec/gcc/x86_64-unknown-linux-gnu/${version}/accel/amdgcn-amdhsa/nm
    cp -a ${amdgcn-amdhsa}/bin/lld $out/libexec/gcc/x86_64-unknown-linux-gnu/${version}/accel/amdgcn-amdhsa/ld

    mkdir -p $out/nix-support
    echo "-B$out/libexec/gcc/x86_64-unknown-linux-gnu/${version}" > $out/nix-support/cc-cflags
  '';

  dontDisableStatic = true;
  doCheck = false;
}
