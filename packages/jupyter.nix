{ coreutils, writeScriptBin, jupyter, cudatoolkit, linuxPackages, bash }:
writeScriptBin "jupyter-lab" ''
  #!${bash}/bin/bash

  set -ev

  export NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu=1
  export NIX_HARDENING_ENABLE=fortify stackprotector pic strictoverflow relro bindnow
  export LD_LIBRARY_PATH="${linuxPackages.nvidia_x11}/lib"

  exec ${jupyter}/bin/jupyter-lab "$@"
''