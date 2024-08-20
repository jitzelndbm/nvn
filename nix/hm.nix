# {
#    root = (builtins.getEnv "HOME") + "/Documents/Notes/index.md";
#
#    behaviour = {
#      strict_closing = false;
#      automatic_creation = false;
#      auto_save = true;
#    };
#
#    appearance = {
#      folding = true;
#      hide_numbers = false;
#    };
#
#    templates = {
#      enable = true;
#      dir = "templates";
#    };
#
#    dates = {
#      enable = true;
#    };
#
#    keys = {
#      leader = " ";
#      map = {
#        createNote = "<leader>C";
#        deleteNote = "<leader>D";
#        eval = "<leader>E";
#        followLink = "<CR>";
#        gotoPrevious = "<Backspace>";
#        nextLink = "<Tab>";
#        openGraph = "<leader>O";
#        previousLink = "<S-Tab>";
#      };
#    };
#  };
self: {
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.nvn;
in {
  options.programs.nvn = {
    enable = mkEnableOption "nvn - neovim notes";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.default;
    };
    root = mkOption {
      type = types.path;
      description = "The file that will be automatically opened when nvn is opened";
    };
    behaviour = {
      strictClosing = lib.mkEnableOption "Enable strict closing";
      automaticCreation = lib.mkEnableOption "Automatically create a note when following a link";
      autoSave = lib.mkEnableOption "Automatically save a note when following a link";
    };
    appearance = {
      folding = lib.mkEnableOption "Enable treesitter markdown folding";
      hideNumbers = lib.mkEnableOption "Hide line numbers inside the editor";
    };
    templates = {
      enable = lib.mkEnableOption "Enable the templates system";
      dir = mkOption {
        type = types.str;
        description = "The path of the templates folder relative to the root";
      };
    };
    extraSettings = mkOption {
      type = types.attrsOf (types.anything);
      description = "Extra Nixvim options";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # NOTE: dankjewel yolanthe <3
      (cfg.package.override
        {
          root = cfg.root;
          extraSettings = cfg.extraSettings;
          behaviour = with cfg.behaviour; {inherit strictClosing automaticCreation autoSave;};
          appearance = with cfg.appearance; {inherit folding hideNumbers;};
          templates = with cfg.templates; {inherit enable dir;};
        })
    ];
  };
}
