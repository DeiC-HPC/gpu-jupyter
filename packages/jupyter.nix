{ coreutils, writeScriptBin, jupyter, cudatoolkit, linuxPackages, bash, cudaSearch }:
writeScriptBin "jupyter-lab" ''
  #!${bash}/bin/bash

  set -e

  export NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu=1
  export NIX_HARDENING_ENABLE=fortify stackprotector pic strictoverflow relro bindnow
  export PATH=$PATH:${cudatoolkit}/bin
  source ${cudaSearch}

  exec ${jupyter}/bin/jupyter-lab "$@"
''
