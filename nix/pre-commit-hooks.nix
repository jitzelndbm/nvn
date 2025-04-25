{ pkgs }:
{
  #selene = {
  #  enable = true;
  #  args = pkgs.lib.flatten [
  #    "--config"
  #    (builtins.toString ../selene.toml)
  #    (builtins.toString ../lua)
  #  ];
  #};
}
