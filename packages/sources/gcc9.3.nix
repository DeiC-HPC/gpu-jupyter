{ fetchurl }:
let
  majorVersion = "9";
  version = "${majorVersion}.3.0";
in
fetchurl {
  url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
  sha256 = "1la2yy27ziasyf0jvzk58y1i5b5bq2h176qil550bxhifs39gqbi";
  passthru = {
    inherit majorVersion version;
  };
}
