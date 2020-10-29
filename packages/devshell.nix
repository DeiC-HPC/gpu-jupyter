{ mkShell, jupyter, gccOffloading, cudaSearch }:

mkShell {
  nativeBuildInputs = [ jupyter gccOffloading ];
  shellHook = ''
    export NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu=1
    export NIX_HARDENING_ENABLE='fortify stackprotector pic strictoverflow relro bindnow'
    source ${cudaSearch}
  '';
}
