{ stdenv, fetchFromGitHub, perl }:

stdenv.mkDerivation {
  name = "nvptx-tools";

  nativeBuildInputs = [
    perl
  ];

  src = fetchFromGitHub {
    owner = "MentorEmbedded";
    repo = "nvptx-tools";
    rev = "5f6f343a302d620b0868edab376c00b15741e39e";
    sha256 = "0panh7kb4jirci8w626zln36hfjybjzbfnspnrwzrvh8xyaijqaw";
  };
}
