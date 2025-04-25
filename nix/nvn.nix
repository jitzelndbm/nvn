{ makeOverridable, nvn-unwrapped }:
makeOverridable nvn-unwrapped
  # Default settings
  (
    let
      root = "~/Documents/Notes";
    in
    {
      inherit root;

      extraOpts = "";
      extraPlugins = [ ];

      index = "README.md";
      autoEvaluation = false;
      autoSave = true;
      handlers = [ ];
      templateFolder = root + "/templates";

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
        # Default gruvbox
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
    }
  )
