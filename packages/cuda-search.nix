{ lib, writeText, writeScript, bash, coreutils }:
let
  wrap = s: "\\e[" + s + "m";
  BRed = wrap "1;31";     # Bold red
  Bold = wrap "0;1";        # Bold
  NC = wrap "0";          # Color Reset
  error = "${BRed}Error${Bold}";

  searchDirs = lib.strings.concatStringsSep " " [
    "/usr/lib"
    "/usr/lib/x86_64-linux-gnu"
    "/run/opengl-driver/lib/"
  ];
  neededLibs = lib.strings.concatStringsSep " " [
    "libcuda.so.1"
    "libnvidia-ptxjitcompiler.so.1"
  ];
  wantedLibs = lib.strings.concatStringsSep " " [
    "libcuda.so.1"
    "libnvidia-*.so.1"
  ];
  makeLibDir = writeScript "make-cuda-libdir.sh" ''
    #!${bash}/bin/bash

    set -e

    CUDA_TMPDIR="$1"

    checkCudaDir() {
      if [[ -z "$1" ]]; then
        return 1
      fi
      for lib in ${neededLibs}; do
        if ! [[ -f "$1/$lib" ]]; then
          return 1
        fi
      done
      return 0
    }

    if [[ -z "$LIBCUDA_DIR" ]]; then
      for d in ${searchDirs}; do
        if checkCudaDir $d; then
          LIBCUDA_DIR=$d
          break
        fi
      done
    fi

    if [[ -z "$LIBCUDA_DIR" ]]; then
      echo
      echo -e "${error}: Could not automatically find libcuda${NC}" >&2
      echo
      exit 1
    fi

    if ! checkCudaDir "$LIBCUDA_DIR"; then
      echo
      echo -e "${error}: '$LIBCUDA_DIR' does not contain the necessary libraries: $neededLibs${NC}" >&2
      echo
      exit 1
    fi

    for lib in ${wantedLibs}; do
      files=($(echo $LIBCUDA_DIR/$lib))
      for f in "''${files[@]}"; do
        ${coreutils}/bin/ln -s $(${coreutils}/bin/realpath -s $f) $CUDA_TMPDIR
      done
    done
  '';
in
writeText "cuda-search.sh" ''
  CUDA_TMPDIR=$(${coreutils}/bin/mktemp -d /tmp/libcuda-dir-XXXXXX)

  if [ $? -ne 0 ]; then
    exit 1
  fi
  trap "${coreutils}/bin/rm -rf $CUDA_TMPDIR" EXIT QUIT TERM

  if ${makeLibDir} $CUDA_TMPDIR; then
    if [ -z "$LD_LIBRARY_PATH" ]; then
      export LD_LIBRARY_PATH="$CUDA_TMPDIR"
    else
      export LD_LIBRARY_PATH="$CUDA_TMPDIR:$LD_LIBRARY_PATH"
    fi
  fi
''
