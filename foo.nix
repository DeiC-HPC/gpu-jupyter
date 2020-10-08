{ gccTest, stdenv, wrapCC, overrideCC, gccStdenv, libstdcxx5 }:

let myStdenv = overrideCC stdenv gccTest;
in

myStdenv.mkDerivation {
  name = "foo";
  src = ./foo.c;

  buildInputs = [ libstdcxx5 ];

  phases = [ "buildPhase" ];
  buildPhase = ''
    g++ -O3 -fopenmp -fno-stack-protector -foffload=-lm -foffload="-misa=sm_35" -xc $src -o $out
  '';
}