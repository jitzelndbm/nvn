{
  description = ''
    A Neovim plugin for taking notes. With Nix it can become a full fledged Neovim distribution!
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
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

              # Javascript (graph)
              nodejs
            ];
          };
        }
      );

      #################################################################

      packages = eachSystem (
        { pkgs, ... }:
        let
          graph = pkgs.callPackage ./nix/graph.nix { };
          plugin = pkgs.callPackage ./nix/plugin.nix { inherit graph; };
          nvn-unwrapped = pkgs.callPackage ./nix/nvn-unwrapped.nix { inherit plugin; };
          nvn = import ./nix/nvn.nix {
            inherit nvn-unwrapped;
            inherit (pkgs.lib) makeOverridable;
          };
        in
        {
          inherit graph plugin nvn;
          development = nvn.override {
            root = "./test_notes";
            index = "README.md";
          };
        }
      );

      apps = eachSystem (
        { system, ... }:
        {
          development = {
            type = "app";
            program = "${self.packages.${system}.development}/bin/nvn";
          };
        }
      );

      #################################################################

      homeManagerModules.${name} = import ./nix/hm.nix self;
    };
}
