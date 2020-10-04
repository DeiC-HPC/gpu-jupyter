{ callPackage, stdenv, fetchurl, texinfo, which, gettext, perl, newlib }:

stdenv.mkDerivation {
  name = "newlib-src";
  src = fetchurl {
    url = "ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz";
    sha256 = "0ricyx792ig2cb2x31b653yb7w7f7mf2111dv5h96lfzmqz9xpaq";
  };
  phases = [ "unpackPhase" ];

  preUnpack = ''
    mkdir $out
    cd $out
  '';
}
