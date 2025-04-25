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
    bun2nix = {
      url = "github:baileyluTCD/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      pre-commit-hooks,
      bun2nix,
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
          selene-3p-language-server = pkgs.callPackage ./nix/selene-3p-language-server.nix {
            inherit (bun2nix.lib.${system}) mkBunDerivation;
          };
        in
        {
          inherit
            nvn
            plugin
            graph
            selene-3p-language-server
            ;
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
              shell = import ./nix/shell.nix {
                inherit pkgs;
                inherit (self.packages.${system}) selene-3p-language-server;
              };
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
          hooks = (import ./nix/pre-commit-hooks.nix { pkgs = pkgsBySystem.${system}; }) // {
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
