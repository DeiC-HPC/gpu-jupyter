{ nixpkgs
, stdenv
, targetPackages
, texinfo
, perl
, gmp
, mpfr
, libmpc
, gettext
, which
, patchelf
, libelf
, isl
, zlib
, buildPackages
, gccSource
, gccNvptx
, cudatoolkit
}:

with stdenv.lib;
with builtins;
let
  inherit (gccSource) version;
  inherit (stdenv) buildPlatform hostPlatform targetPlatform;

  patches =
    optional (targetPlatform != hostPlatform) "${nixpkgs}/pkgs/development/compilers/gcc/libstdc++-target.patch"
    ++ [
      "${nixpkgs}/pkgs/development/compilers/gcc/no-sys-dirs.patch"
      ../sources/gcn-nvptx-offloading-mkoffload-handle--fpic--fPIC.diff
    ];
in
stdenv.mkDerivation {
  pname = "gcc${version}-offload";
  inherit version;

  builder = "${nixpkgs}/pkgs/development/compilers/gcc/builder.sh";

  src = gccSource;

  inherit patches;

  outputs = [ "out" "man" "info" "lib" ];
  setOutputFlags = false;
  NIX_NO_SELF_RPATH = false;

  libc_dev = stdenv.cc.libc_dev;

  hardeningDisable = [ "format" "pie" ];

  postPatch = ''
    configureScripts=$(find . -name configure)
    for configureScript in $configureScripts; do
      patchShebangs $configureScript
    done
  '' + (
    if targetPlatform != hostPlatform || stdenv.cc.libc != null then
    # On NixOS, use the right path to the dynamic linker instead of
    # `/lib/ld*.so'.
      let
        libc = stdenv.cc.libc;
      in
      (
        '' echo "fixing the \`GLIBC_DYNAMIC_LINKER', \`UCLIBC_DYNAMIC_LINKER', and \`MUSL_DYNAMIC_LINKER' macros..."
           for header in "gcc/config/"*-gnu.h "gcc/config/"*"/"*.h
           do
             grep -q _DYNAMIC_LINKER "$header" || continue
             echo "  fixing \`$header'..."
             sed -i "$header" \
                 -e 's|define[[:blank:]]*\([UCG]\+\)LIBC_DYNAMIC_LINKER\([0-9]*\)[[:blank:]]"\([^\"]\+\)"$|define \1LIBC_DYNAMIC_LINKER\2 "${libc.out}\3"|g' \
                 -e 's|define[[:blank:]]*MUSL_DYNAMIC_LINKER\([0-9]*\)[[:blank:]]"\([^\"]\+\)"$|define MUSL_DYNAMIC_LINKER\1 "${libc.out}\2"|g'
           done
        ''
      )
    else ""
  );

  crossStageStatic = false;
  staticCompiler = false;
  crossMingw = false;
  noSysDirs = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ texinfo which gettext perl ];

  # For building runtime libs
  depsBuildTarget =
    (
      if hostPlatform == buildPlatform then [
        targetPackages.stdenv.cc.bintools # newly-built gcc will be used
      ] else assert targetPlatform == hostPlatform; [
        # build != host == target
        stdenv.cc
      ]
    )
    ++ [ patchelf ];

  buildInputs = [
    gmp
    mpfr
    libmpc
    libelf
    targetPackages.stdenv.cc.bintools # For linking code at run-time
    isl
    zlib
  ];

  dontDisableStatic = true;

  configurePlatforms = [ "build" "host" "target" ];

  configureFlags = (import "${nixpkgs}/pkgs/development/compilers/gcc/common/configure-flags.nix" {
    inherit stdenv targetPackages version gmp mpfr libmpc libelf isl;
    libcCross = null;
    crossStageStatic = false;
    enableShared = true;
    enableMultilib = false;
    enablePlugin = false;
    enableLTO = true;
    langC = true;
    langCC = true;
    langFortran = true;
    langAda = false;
    langGo = false;
    langObjC = false;
    langObjCpp = false;
    langJit = false;
  }) ++ [
    "--enable-offload-targets=nvptx-none=${gccNvptx}/nvptx-none"
    "--with-cuda-driver=${cudatoolkit}"
    "--disable-bootstrap"
  ];

  targetConfig = if targetPlatform != hostPlatform then targetPlatform.config else null;

  dontStrip = true;

  # Setting $CPATH and $LIBRARY_PATH to make sure both `gcc' and `xgcc' find the
  # library headers and binaries, regarless of the language being compiled.
  #
  # Likewise, the LTO code doesn't find zlib.
  #
  # Cross-compiling, we need gcc not to read ./specs in order to build the g++
  # compiler (after the specs for the cross-gcc are created). Having
  # LIBRARY_PATH= makes gcc read the specs from ., and the build breaks.

  CPATH = optionals (targetPlatform == hostPlatform) (makeSearchPathOutput "dev" "include" [ zlib ]);

  LIBRARY_PATH = (optionals (targetPlatform == hostPlatform) (makeLibraryPath [ zlib ])) + ":${cudatoolkit}/lib/stubs";

  enableParallelBuilding = true;
  enableMultilib = false;

  postFixup = ''
    # Fixing up libgomp
    PREV_RPATH=`patchelf --print-rpath $lib/lib/libgomp.so.1`
    NEW_RPATH=`echo "$PREV_RPATH:$lib/lib"`
    patchelf --set-rpath "$NEW_RPATH" $lib/lib/libgomp.so.1 && echo OK
  '';

  inherit (stdenv) is64bit;

  passthru = {
    langC = true;
    langCC = true;
    langFortran = true;
    langObjC = false;
    langObjCpp = false;
    langAda = false;
    langGo = false;
    inherit version;
    isGNU = true;
  };
}
