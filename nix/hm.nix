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
      description = "The path that will be automatically opened when nvn is opened";
    };

    index = mkOption {
      type = types.str;
      description = "The default file that is searched in directories";
      default = "README.md";
    };

    autoEvaluation = mkOption {
      type = types.bool;
      default = false;
    };

    autoSave = mkOption {
      type = types.bool;
      default = true;
    };

    handlers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            pattern = mkOption { type = types.str; };
            handler = mkOption { type = types.str; };
          };
        }
      );
      description = "Handlers for links in the plugin";
      default = [ ];
    };

    templateFolder = mkOption {
      type = types.str;
      description = "path to the templates folder relative to the root";
      default = "templates";
    };

    extraOpts = mkOption {
      type = types.str;
      description = "Extra options";
      default = "";
    };

    extraPlugins = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            plugin = mkOption { type = types.package; };
            config = mkOption { type = types.str; };
          };
        }
      );
      description = "Extra plugins";
      default = [ ];
    };

    keymaps = {
      leader = mkOption {
        type = types.str;
        description = "This is the key that precedes all Nvn shortcuts";
      };
      createNote = mkOption { type = types.str; };
      deleteNote = mkOption { type = types.str; };
      eval = mkOption { type = types.str; };
      followLink = mkOption { type = types.str; };
      gotoPrevious = mkOption { type = types.str; };
      nextLink = mkOption { type = types.str; };
      openGraph = mkOption { type = types.str; };
      previousLink = mkOption { type = types.str; };
    };

    colors = mkOption {
      type = lib.types.attrsOf types.str;
      # Gruvbox as default
      default = {
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
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # NOTE: dankjewel yolanthe <3
      (cfg.package.override {
        inherit (cfg)
          root
          index
          handlers
          templateFolder
          extraOpts
          extraPlugins
          keymaps
          colors
          autoSave
          autoEvaluation
          ;
      })
    ];
  };
}
