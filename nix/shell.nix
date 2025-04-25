{ pkgs, ... }:
{
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      # Lua tools
      stylua
      luajit
      lua-language-server
      luajitPackages.ldoc

      # Nix
      nixd
      nixfmt-rfc-style

      # Javascript (graph)
      nodejs
    ];
  };
}
