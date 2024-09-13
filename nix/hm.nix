self:
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.programs.nvn;
in
{
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
      default = { };
    };
    keys = {
      leader = mkOption {
        type = types.str;
        description = "This is the key that precedes all Nvn shortcuts";
      };
      map = {
        createNote = mkOption { type = types.str; };
        deleteNote = mkOption { type = types.str; };
        eval = mkOption { type = types.str; };
        followLink = mkOption { type = types.str; };
        gotoPrevious = mkOption { type = types.str; };
        nextLink = mkOption { type = types.str; };
        openGraph = mkOption { type = types.str; };
        previousLink = mkOption { type = types.str; };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # NOTE: dankjewel yolanthe <3
      (cfg.package.override {
        root = cfg.root;
        extraSettings = cfg.extraSettings;
        behaviour = with cfg.behaviour; {
          inherit strictClosing automaticCreation autoSave;
        };
        appearance = with cfg.appearance; {
          inherit folding hideNumbers;
        };
        templates = with cfg.templates; {
          inherit enable dir;
        };
      })
    ];
  };
}
