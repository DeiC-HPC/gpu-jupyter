{ gccTest, stdenv }:

stdenv.mkDerivation {
  phases = [ "buildPhase" ];
  buildPhase = ''
    ${gccTest}/bin/gcc -o $out
  '';
}