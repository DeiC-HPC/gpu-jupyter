{ fetchurl }:
let
  majorVersion = "11";
  version = "${majorVersion}.2.0";
in
fetchurl {
  url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
  sha256 = "12zs6vd2rapp42x154m479hg3h3lsafn3xhg06hp5hsldd9xr3nh";
  passthru = {
    inherit majorVersion version;
  };
}