{ stdenv, fetchFromGitHub, cmake, libxml2, libffi, ncurses, zlib, libpfm, python3, libbfd, fetchurl, file }:

stdenv.mkDerivation rec {
  name = "amdgcn-amdhsa";

  enableParallelBuilding = true;
  version = "9.0.1";

  src = fetchurl {
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/llvm-${version}.src.tar.xz";
    sha256 = "16hwp3qa54c3a3v7h8nlw0fh5criqh0hlr1skybyk0cz70gyx880";
  };

  lld = fetchurl {
    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/lld-${version}.src.tar.xz";
    sha256 = "10hckfxpapfnh6y9apjiya2jpw9nmbbmh8ayijx89mrg7snjn9l6";
  };

  unpackPhase = ''
    unpackFile $src
    unpackFile ${lld}
    mv llvm-${version}* llvm
    mv lld-* lld
    sourceRoot=$PWD/llvm
  '';
  outputs = [ "out" ];

  nativeBuildInputs = [ cmake python3 file ];

  buildInputs = [ file libxml2 libffi libpfm ];

  propagatedBuildInputs = [ ncurses zlib ];


  postPatch =  ''
    # FileSystem permissions tests fail with various special bits
    substituteInPlace unittests/Support/CMakeLists.txt \
      --replace "Path.cpp" ""
    rm unittests/Support/Path.cpp
    patchShebangs test/BugPoint/compile-custom.ll.py
  '';

  # hacky fix: created binaries need to be run before installation
  preBuild = ''
    mkdir -p $out/
    #ln -sv $PWD/lib $out
  '';

  # E.g. mesa.drivers use the build-id as a cache key (see #93946):
  LDFLAGS = "-Wl,--build-id=sha1";

  cmakeFlags = with stdenv; [
    #"-DLLVM_BUILD_TESTS=ON"
    #"-DLLVM_ENABLE_FFI=ON"
    #"-DLLVM_ENABLE_RTTI=ON"
    "-DLLVM_HOST_TRIPLE=${stdenv.hostPlatform.config}"
    "-DLLVM_DEFAULT_TARGET_TRIPLE=${stdenv.hostPlatform.config}"
    #"-DLLVM_ENABLE_DUMP=ON"
    #"-DLLVM_LINK_LLVM_DYLIB=ON"
    "-DLLVM_BINUTILS_INCDIR=${libbfd.dev}/include"
    # Flags for GPU
    "-D 'LLVM_TARGETS_TO_BUILD=X86;AMDGPU'"
    "-DLLVM_ENABLE_PROJECTS=lld"
  ];

  postBuild = ''
    rm -fR $out
    mkdir -p $out/bin

    echo HELLO
    find . -iname llvm-nm
    file bin/llvm-nm
    file tools/llvm-nm
    ls -la *
    echo HELLO_STOP

    cp -a bin/llvm-ar $out/bin/
    ln -s $out/bin/llvm-ar $out/bin/ar
    ln -s $out/bin/llvm-ar $out/bin/ranlib
    cp -a bin/llvm-mc $out/bin/
    ln -s $out/bin/llvm-mc $out/bin/as
    cp -a bin/llvm-nm $out/bin/llvm-nm
    cp -a bin/lld $out/bin/
    ln -s $out/bin/lld $out/bin/ld
    #cp tools/llvm-nm/CMakeFiles/llvm-nm.dir/llvm-nm.cpp.o $out/bin/nm
    cp -a bin/llvm-nm $out/bin/nm
    cp -ra tools $out/tools
  '';

  dontInstall = true;

  preCheck = ''
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}$PWD/lib
  '';

  #postInstall = ''
  #  #mkdir -p $python/share
  #  #mv $out/share/opt-viewer $python/share/opt-viewer
  #  #moveToOutput "lib/libLLVM-*" "$lib"
  #  #moveToOutput "lib/libLLVM${stdenv.hostPlatform.extensions.sharedLibrary}" "$lib"
  #  #substituteInPlace "$out/lib/cmake/llvm/LLVMExports-release.cmake" \
  #  #  --replace "\''${_IMPORT_PREFIX}/lib/libLLVM-" "$lib/lib/libLLVM-"
  #  ln -s $out/bin/llvm-ar $out/bin/ar
  #  ln -s $out/bin/llvm-ar $out/bin/ranlib
  #  ln -s $out/bin/llvm-mc $out/bin/as
  #  # Det er kun den her, der fejler... De andre er object filer åbenbart
  #  ln -s $out/bin/llvm-nm $out/bin/nm
  #  ln -s $out/bin/lld $out/bin/ld
  #'';

  doCheck = stdenv.isLinux && (!stdenv.isx86_32) && (!stdenv.hostPlatform.isMusl);

  #checkTarget = "check-all";

  requiredSystemFeatures = [ "big-parallel" ];
}


#{ stdenv, fetchFromGitHub, cmake, libxml2, libffi, ncurses, zlib, libpfm, python3, libbfd, fetchurl }:
#
#stdenv.mkDerivation rec {
#  name = "amdgcn-amdhsa";
#
#  enableParallelBuilding = true;
#  version = "11.0.0";
#
#  src = fetchurl {
#    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/llvm-${version}.src.tar.xz";
#    sha256 = "0s94lwil98w7zb7cjrbnxli0z7gklb312pkw74xs1d6zk346hgwi";
#  };
#
#  lld = fetchurl {
#    url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-${version}/lld-${version}.src.tar.xz";
#    sha256 = "077xyh7sij6mhp4dc4kdcmp9whrpz332fa12rwxnzp3wgd5bxrzg";
#  };
#
#  unpackPhase = ''
#    unpackFile $src
#    unpackFile ${lld}
#    mv llvm-${version}* llvm
#    mv lld-* lld
#    sourceRoot=$PWD/llvm
#  '';
#
#  #outputs = [ "out" "python" "lib" ];
#  outputs = [ "out" ];
#
#  nativeBuildInputs = [ cmake python3 ];
#
#  buildInputs = [ libxml2 libffi libpfm ];
#
#  propagatedBuildInputs = [ ncurses zlib ];
#
#  #postPatch =  ''
#  #  substitute '${./llvm-outputs.patch}' ./llvm-outputs.patch --subst-var lib
#  #  patch -p1 < ./llvm-outputs.patch
#  #  # FileSystem permissions tests fail with various special bits
#  #  substituteInPlace unittests/Support/CMakeLists.txt \
#  #    --replace "Path.cpp" ""
#  #  rm unittests/Support/Path.cpp
#  #  patchShebangs test/BugPoint/compile-custom.ll.py
#  #'';
#
#  postPatch =  ''
#    # FileSystem permissions tests fail with various special bits
#    substituteInPlace unittests/Support/CMakeLists.txt \
#      --replace "Path.cpp" ""
#    rm unittests/Support/Path.cpp
#    patchShebangs test/BugPoint/compile-custom.ll.py
#  '';
#
#  # hacky fix: created binaries need to be run before installation
#  preBuild = ''
#    mkdir -p $out/
#    #ln -sv $PWD/lib $out
#  '';
#
#  # E.g. mesa.drivers use the build-id as a cache key (see #93946):
#  LDFLAGS = "-Wl,--build-id=sha1";
#
#  cmakeFlags = with stdenv; [
#    #"-DLLVM_BUILD_TESTS=ON"
#    #"-DLLVM_ENABLE_FFI=ON"
#    #"-DLLVM_ENABLE_RTTI=ON"
#    "-DLLVM_HOST_TRIPLE=${stdenv.hostPlatform.config}"
#    "-DLLVM_DEFAULT_TARGET_TRIPLE=${stdenv.hostPlatform.config}"
#    #"-DLLVM_ENABLE_DUMP=ON"
#    #"-DLLVM_LINK_LLVM_DYLIB=ON"
#    "-DLLVM_BINUTILS_INCDIR=${libbfd.dev}/include"
#    # Flags for GPU
#    "-D 'LLVM_TARGETS_TO_BUILD=X86;AMDGPU'"
#    "-DLLVM_ENABLE_PROJECTS=lld"
#  ];
#
#  postBuild = ''
#    rm -fR $out
#    mkdir -p $out/bin
#
#    cp -a bin/llvm-ar $out/bin/ar
#    cp -a bin/llvm-ar $out/bin/ranlib
#    cp -a bin/llvm-mc $out/bin/as
#    cp -a bin/llvm-nm $out/bin/nm
#    cp -a bin/lld $out/bin/ld
#  '';
#
#  dontInstall = false;
#
#  preCheck = ''
#    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH''${LD_LIBRARY_PATH:+:}$PWD/lib
#  '';
#
#  #postInstall = ''
#  #  #mkdir -p $python/share
#  #  #mv $out/share/opt-viewer $python/share/opt-viewer
#  #  #moveToOutput "lib/libLLVM-*" "$lib"
#  #  #moveToOutput "lib/libLLVM${stdenv.hostPlatform.extensions.sharedLibrary}" "$lib"
#  #  #substituteInPlace "$out/lib/cmake/llvm/LLVMExports-release.cmake" \
#  #  #  --replace "\''${_IMPORT_PREFIX}/lib/libLLVM-" "$lib/lib/libLLVM-"
#  #  ln -s $out/bin/llvm-ar $out/bin/ar
#  #  ln -s $out/bin/llvm-ar $out/bin/ranlib
#  #  ln -s $out/bin/llvm-mc $out/bin/as
#  #  # Det er kun den her, der fejler... De andre er object filer åbenbart
#  #  ln -s $out/bin/llvm-nm $out/bin/nm
#  #  ln -s $out/bin/lld $out/bin/ld
#  #'';
#
#  doCheck = stdenv.isLinux && (!stdenv.isx86_32) && (!stdenv.hostPlatform.isMusl);
#
#  #checkTarget = "check-all";
#
#  requiredSystemFeatures = [ "big-parallel" ];
#}
