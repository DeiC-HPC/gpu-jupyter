{ gccTest, stdenv, wrapCC }:

let cc = wrapCC gccTest;
in

stdenv.mkDerivation {
  name = "foo";
  phases = [ "buildPhase" ];
  buildPhase = ''
    echo 'int main(){}' | ${cc}/bin/gcc -xc - -o $out
  '';
}