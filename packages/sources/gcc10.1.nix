{ fetchurl }:
let
  majorVersion = "10";
  version = "${majorVersion}.1.0";
in
fetchurl {
  url = "mirror://gcc/releases/gcc-${version}/gcc-${version}.tar.xz";
  sha256 = "18kyds3ss4j7in8shlsbmjafdhin400mq739d0dnyrabhhiqm2dn";
  passthru = {
    inherit majorVersion version;
  };
}
