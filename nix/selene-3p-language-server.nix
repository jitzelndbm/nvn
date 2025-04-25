{
  fetchFromGitHub,
  mkBunDerivation,
}:
mkBunDerivation {
  pname = "selene-3p-language-server";
  version = "1.0.2";

  bunNix = ./bun.nix;
  index = "./src/selene-bin.ts";

  src = fetchFromGitHub {
    rev = "main";
    owner = "antonk52";
    repo = "lua-3p-language-servers";
    hash = "sha256-mHYqI/u31M/WZt5+eEsFO6Betj39Rmf9kNSzvFi/0Qk=";
  };
}
