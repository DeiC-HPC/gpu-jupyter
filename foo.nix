{ gccTest, stdenv, wrapCC }:

let cc = wrapCC gccTest;
in

stdenv.mkDerivation {
  name = "foo";
  src = ./foo.c;
  phases = [ "buildPhase" ];
  buildPhase = ''
    ${cc}/bin/g++ -O3 -fopenmp -fno-stack-protector -foffload=-lm -foffload="-misa=sm_35" -xc $src -o $out
  '';
}