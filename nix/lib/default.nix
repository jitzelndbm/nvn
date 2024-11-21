{
  pkgs,
  src,
  name,
}:
let
  inherit (pkgs) wrapNeovimUnstable neovim-unwrapped buildNpmPackage;
  inherit (pkgs.vimUtils) buildVimPlugin;
  inherit (pkgs.lib) makeOverridable;
  inherit (pkgs.stdenv) mkDerivation;

  mkGraph = buildNpmPackage {
    name = "nvn-graph";
    src = ../../.;
    npmBuildScript = "build";
    npmDepsHash = "sha256-Zz4/tUALxbVE9zzXjn5lWESZ4o88zQk1qlYNSBXcnHI=";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp -r build/* $out/lib
      runHook postInstall
    '';
  };

  defaultSettings = {
    extraOpts = "";
    extraPlugins = [ ];
    keymaps = {
      leader = " ";
      createNote = "<leader>C";
      deleteNote = "<leader>D";
      eval = "<leader>E";
      followLink = "<CR>";
      gotoPrevious = "<Backspace>";
      nextLink = "<Tab>";
      openGraph = "<leader>O";
      previousLink = "<S-Tab>";
    };
    colors = {
      base00 = "#1d2021";
      base01 = "#3c3836";
      base02 = "#504945";
      base03 = "#665c54";
      base04 = "#bdae93";
      base05 = "#d5c4a1";
      base06 = "#ebdbb2";
      base07 = "#fbf1c7";
      base08 = "#fb4934";
      base09 = "#fe8019";
      base0A = "#fabd2f";
      base0B = "#b8bb26";
      base0C = "#8ec07c";
      base0D = "#83a598";
      base0E = "#d3869b";
      base0F = "#d65d0e";
    };
  };

	# Combine the graph derivation and build the neovim plugin
  mkPlugin = mkDerivation (finalAttrs: {
		name = "nvn";

    src = ../../.;

    buildInputs = [ mkGraph ];

    installPhase = ''
      mkdir -p $out $out/lib $out/lua

      cp -r lua/* $out/lua/

      cp -r ${mkGraph}/lib/graph.min.js $out/lib/
			cp -r graph/index.html $out/lib/graph.html
    '';
  });

  mkNvnUnwrapped =
    settings:
    wrapNeovimUnstable neovim-unwrapped (
      import ./config.nix {
        inherit pkgs settings;
        plugin = mkPlugin;
      }
    );

  mkNvn = makeOverridable mkNvnUnwrapped defaultSettings;
in
{
  inherit
    mkPlugin
    mkNvnUnwrapped
    mkNvn
    mkGraph
    ;
}
