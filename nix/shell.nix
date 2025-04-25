{ pkgs, selene-3p-language-server, ... }:
{
  buildInputs = with pkgs; [
    # Lua tools
    stylua
    luajit
    lua-language-server
    luajitPackages.ldoc
    selene-3p-language-server
    selene

    # Nix
    nil
    nixfmt-rfc-style

    # Javascript (graph)
    nodejs
  ];
}
