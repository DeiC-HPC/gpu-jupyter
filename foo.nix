{ gccTest, stdenv, wrapCC }:

let cc = wrapCC gccTest;
in

stdenv.mkDerivation {
  phases = [ "buildPhase" ];
  buildPhase = ''
    ${cc}/bin/gcc -o $out
  '';
}