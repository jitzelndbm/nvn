{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      pre-commit-hooks,
      ...
    }:
    let
      name = "nvn";

      fa = nixpkgs.lib.genAttrs [ "x86_64-linux" ];

      pkgsBySystem = fa (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = false;
        }
      );

      treefmtEval = fa (system: treefmt-nix.lib.evalModule pkgsBySystem.${system} ./nix/formatters.nix);
    in
    {
      packages = fa (
        system:
        let
          pkgs = pkgsBySystem.${system};
          graph = pkgs.callPackage ./nix/graph.nix { };
          plugin = pkgs.callPackage ./nix/plugin.nix { inherit graph; };
          nvn-unwrapped = pkgs.callPackage ./nix/nvn-unwrapped.nix { inherit plugin; };
          nvn = import ./nix/nvn.nix {
            inherit nvn-unwrapped;
            inherit (pkgs.lib) makeOverridable;
          };
        in
        {
          inherit nvn plugin graph;
          default = self.packages.${system}.nvn;
        }
      );

      devShells = fa (
        system:
        let
          pkgs = pkgsBySystem.${system};
        in
        {
          default =
            let
              inherit (pkgs) mkShell nil;
              inherit (pkgs.lib) concatLines;
              inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;

              treefmt = treefmtEval.${system}.config.build.wrapper;
              shell = import ./nix/shell.nix { inherit pkgs; };
            in
            mkShell (
              shell
              // {
                packages = (shell.packages or [ ]) ++ [
                  treefmt
                  nil
                  enabledPackages
                ];

                shellHook = concatLines [
                  (shell.shellHook or "")
                  shellHook
                ];
              }
            );
        }
      );

      formatter = fa (system: treefmtEval.${system}.config.build.wrapper);

      checks = fa (system: {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = (import ./nix/pre-commit-hooks.nix) // {
            treefmt = {
              enable = true;
              package = treefmtEval.${system}.config.build.wrapper;
            };
          };
        };
      });

      homeManagerModules.${name} = import ./nix/hm.nix self;
    };
}
