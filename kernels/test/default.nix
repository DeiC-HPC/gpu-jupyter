{self, pkgs, ...}:
{
  name = "test";
  displayName = "test";
  language = "python";
  argv = [
    "${pkgs.python3}/bin/python3"
    "-m"
    "ipykernel_launcher"
    "-f"
    "{connection_file}"
  ];
  codemirrorMode = "python";
  logo64 = "./logo.png";
}