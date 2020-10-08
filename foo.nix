{ gccTest, stdenv, wrapCC, overrideCC, gccStdenv, libstdcxx5 }:

stdenv.mkDerivation {
  name = "foo";
  src = ./foo.cpp;

  buildInputs = [ libstdcxx5 ];

  phases = [ "buildPhase" ];
  buildPhase = ''
    ${gccTest}/bin/g++ -O3 -fopenmp -fno-stack-protector -foffload=-lm -foffload="-misa=sm_35" -xc $src -o $out
  '';
}