{ fetchurl }:
let
  majorVersion = "10";
  version = "${majorVersion}.2.0";
in
fetchurl {
  url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
  sha256 = "130xdkhmz1bc2kzx061s3sfwk36xah1fw5w332c0nzwwpdl47pdq";
  passthru = {
    inherit majorVersion version;
  };
}
