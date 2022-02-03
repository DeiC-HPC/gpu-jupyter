{ mkShell, jupyter, gccOffloading, cudaSearch, nvhpc, gnumake, rocm-llvm, libcxxClang, libcxxStdenv }:

mkShell {
  nativeBuildInputs = [ jupyter gccOffloading nvhpc rocm-llvm gnumake ];
  shellHook = ''
    export NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu=1
    export NIX_HARDENING_ENABLE='fortify stackprotector pic strictoverflow relro bindnow'
    source ${cudaSearch}
  '';
  packages = [ jupyter gccOffloading nvhpc rocm-llvm gnumake ];
}
