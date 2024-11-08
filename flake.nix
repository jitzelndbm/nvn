{
  description = ''
    A Neovim plugin for taking notes. With Nix it can become a full fledged Neovim distribution!
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvim,
      treefmt-nix,
      ...
    }:
    let
      name = "nvn";
      systems = [ "x86_64-linux" ];
      eachSystem =
        f:
        let
          forAllSystems = nixpkgs.lib.genAttrs systems;
        in
        forAllSystems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs { inherit system; };
          }
        );
    in
    {
      formatter = eachSystem (
        { pkgs, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        treefmtEval.config.build.wrapper
      );

      #################################################################

      devShells = eachSystem (
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
            ];
          };
        }
      );

      #################################################################

      packages = eachSystem (
        { pkgs, system }:
        let
          lib = import ./nix/lib {
            inherit pkgs name;
            nixvim = nixvim.legacyPackages.${system};
            src = self;
          };
        in
        {
          default = lib.mkNvnWithDefaults;
          noNixVim = lib.mkNvnWithDefaultsFast;
          plugin = lib.mkPlugin;
        }
      );

      apps = eachSystem (
        { system, ... }:
        {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/${name}";
          };
        }
      );

      #################################################################

      homeManagerModules.${name} = import ./nix/hm.nix self;
    };
}
