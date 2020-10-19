{ makeWrapper, symlinkJoin, jupyter, cudatoolkit, linuxPackages }:
symlinkJoin {
  name = "jupyter";
  paths = [ jupyter ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/jupyter-lab --prefix PATH : "${cudatoolkit}/bin" --prefix LD_LIBRARY_PATH : "${linuxPackages.nvidia_x11}/lib"
  '';
}
