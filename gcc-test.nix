{ nixpkgs
, stdenv, targetPackages, fetchurl, fetchpatch
, langC ? true, langCC ? true, langFortran ? false
, langAda ? false
, langObjC ? stdenv.targetPlatform.isDarwin
, langObjCpp ? stdenv.targetPlatform.isDarwin
, langGo ? false
, profiledCompiler ? false
, langJit ? false
, staticCompiler ? false
, enableShared ? true
, enableLTO ? true
, texinfo ? null
, perl ? null # optional, for texi2pod (then pod2man)
, gmp, mpfr, libmpc, gettext, which, patchelf
, libelf                      # optional, for link-time optimizations (LTO)
, isl ? null # optional, for the Graphite optimization framework.
, zlib ? null
, enablePlugin ? stdenv.hostPlatform == stdenv.buildPlatform # Whether to support user-supplied plug-ins
, name ? "gcc"
, threadsCross ? null # for MinGW
, crossStageStatic ? false
, # Strip kills static libs of other archs (hence no cross)
  stripped ? stdenv.hostPlatform == stdenv.buildPlatform
          && stdenv.targetPlatform == stdenv.hostPlatform
, buildPackages
}:

with stdenv.lib;
with builtins;

let majorVersion = "10";
    version = "${majorVersion}.2.0";
    libcCross = null;

    inherit (stdenv) buildPlatform hostPlatform targetPlatform;

    patches =
         optional (targetPlatform != hostPlatform) "${nixpkgs}/pkgs/development/compilers/gcc/libstdc++-target.patch"
      ++ [ "${nixpkgs}/pkgs/development/compilers/gcc/no-sys-dirs.patch" ];

    /* Cross-gcc settings (build == host != target) */
    stageNameAddon = if crossStageStatic then "stage-static" else "stage-final";
    crossNameAddon = optionalString (targetPlatform != hostPlatform) "${targetPlatform.config}-${stageNameAddon}-";
in

stdenv.mkDerivation {
  pname = "${crossNameAddon}${name}${if stripped then "" else "-debug"}";
  inherit version;

  builder = "${nixpkgs}/pkgs/development/compilers/gcc/builder.sh";

  src = fetchurl {
    url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
    sha256 = "130xdkhmz1bc2kzx061s3sfwk36xah1fw5w332c0nzwwpdl47pdq";
  };

  inherit patches;

  outputs = [ "out" "man" "info" "lib" ];
  setOutputFlags = false;
  NIX_NO_SELF_RPATH = true;

  libc_dev = stdenv.cc.libc_dev;

  hardeningDisable = [ "format" "pie" ];

  # This should kill all the stdinc frameworks that gcc and friends like to
  # insert into default search paths.
  prePatch = stdenv.lib.optionalString hostPlatform.isDarwin ''
    substituteInPlace gcc/config/darwin-c.c \
      --replace 'if (stdinc)' 'if (0)'

    substituteInPlace libgcc/config/t-slibgcc-darwin \
      --replace "-install_name @shlib_slibdir@/\$(SHLIB_INSTALL_NAME)" "-install_name ''${!outputLib}/lib/\$(SHLIB_INSTALL_NAME)"

    substituteInPlace libgfortran/configure \
      --replace "-install_name \\\$rpath/\\\$soname" "-install_name ''${!outputLib}/lib/\\\$soname"
  '';

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
        libc = if libcCross != null then libcCross else stdenv.cc.libc;
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
        + stdenv.lib.optionalString (targetPlatform.libc == "musl")
        ''
            sed -i gcc/config/linux.h -e '1i#undef LOCAL_INCLUDE_DIR'
        ''
        )
    else "")
      + stdenv.lib.optionalString targetPlatform.isAvr ''
	        makeFlagsArray+=(
	           'LIMITS_H_TEST=false'
	        )
	      '';

  inherit staticCompiler crossStageStatic libcCross;
  crossMingw = false;
  noSysDirs = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ texinfo which gettext ]
    ++ (optional (perl != null) perl);

  # For building runtime libs
  depsBuildTarget =
    (
      if hostPlatform == buildPlatform then [
        targetPackages.stdenv.cc.bintools # newly-built gcc will be used
      ] else assert targetPlatform == hostPlatform; [ # build != host == target
        stdenv.cc
      ]
    )
    ++ optional targetPlatform.isLinux patchelf;

  buildInputs = [
    gmp mpfr libmpc libelf
    targetPackages.stdenv.cc.bintools # For linking code at run-time
    isl
    zlib
  ];

  depsTargetTarget = optional (!crossStageStatic && threadsCross != null) threadsCross;

  NIX_LDFLAGS = stdenv.lib.optionalString  hostPlatform.isSunOS "-lm -ldl";

  preConfigure = import "${nixpkgs}/pkgs/development/compilers/gcc/common/pre-configure.nix" {
    inherit (stdenv) lib;
    inherit version hostPlatform langAda langGo;
  };

  dontDisableStatic = true;

  # TODO(@Ericson2314): Always pass "--target" and always prefix.
  configurePlatforms = [ "build" "host" ] ++ stdenv.lib.optional (targetPlatform != hostPlatform) "target";

  configureFlags = (import "${nixpkgs}/pkgs/development/compilers/gcc/common/configure-flags.nix" {
    inherit
      stdenv
      targetPackages
      crossStageStatic libcCross
      version

      gmp mpfr libmpc libelf isl

      enableLTO
      enablePlugin
      enableShared

      langC
      langCC
      langFortran
      langAda
      langGo
      langObjC
      langObjCpp
      langJit
      ;
    enableMultilib = false;
  }) ++ [ "--disable-bootstrap" ];

  targetConfig = if targetPlatform != hostPlatform then targetPlatform.config else null;

#  buildFlags = optional
#    (targetPlatform == hostPlatform && hostPlatform == buildPlatform)
#    (if profiledCompiler then "profiledbootstrap" else "bootstrap");

  dontStrip = !stripped;

  installTargets = optional stripped "install-strip";

  # https://gcc.gnu.org/install/specific.html#x86-64-x-solaris210
  ${if hostPlatform.system == "x86_64-solaris" then "CC" else null} = "gcc -m64";

  # Setting $CPATH and $LIBRARY_PATH to make sure both `gcc' and `xgcc' find the
  # library headers and binaries, regarless of the language being compiled.
  #
  # Likewise, the LTO code doesn't find zlib.
  #
  # Cross-compiling, we need gcc not to read ./specs in order to build the g++
  # compiler (after the specs for the cross-gcc are created). Having
  # LIBRARY_PATH= makes gcc read the specs from ., and the build breaks.

  CPATH = optionals (targetPlatform == hostPlatform) (makeSearchPathOutput "dev" "include" ([]
    ++ optional (zlib != null) zlib
  ));

  LIBRARY_PATH = optionals (targetPlatform == hostPlatform) (makeLibraryPath (optional (zlib != null) zlib));

  inherit
    (import "${nixpkgs}/pkgs/development/compilers/gcc/common/extra-target-flags.nix" {
      inherit stdenv crossStageStatic libcCross threadsCross;
    })
    EXTRA_FLAGS_FOR_TARGET
    EXTRA_LDFLAGS_FOR_TARGET
    ;

  passthru = {
    inherit langC langCC langObjC langObjCpp langAda langFortran langGo version;
    isGNU = true;
  };

  enableParallelBuilding = true;
  enableMultilib = false;

  inherit (stdenv) is64bit;
}