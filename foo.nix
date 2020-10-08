{ gccTest, stdenv, wrapCC }:

let cc = wrapCC gccTest;
in

stdenv.mkDerivation {
  name = "foo";
  phases = [ "buildPhase" ];
  buildPhase = ''
    ${cc}/bin/gcc -o $out
  '';
}