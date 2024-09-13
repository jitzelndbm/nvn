{
  pkgs,
  nixvim,
  src,
  name,
}:
let
  inherit (pkgs.lib) makeOverridable;

  mkPlugin = pkgs.vimUtils.buildVimPlugin { inherit name src; };

  boolToStr = bool: if bool then "true" else "false";

  mkPluginConfig = settings: {
    extraPlugins = [ mkPlugin ];

    extraConfigLua =
      #lua
      ''
        require'nvn'.setup {
          root = "${settings.root}",

          behaviour = {
            strict_closing = ${boolToStr settings.behaviour.strictClosing},
            auto_save = ${boolToStr settings.behaviour.autoSave},
            automatic_creation = ${boolToStr settings.behaviour.automaticCreation},
          },

          appearance = {
            folding = ${boolToStr settings.appearance.folding},
            hide_numbers = ${boolToStr settings.appearance.hideNumbers},
          },

          templates = {
            enabled = ${boolToStr settings.templates.enable},
            dir = "${settings.templates.dir}",
          },

          dates = {
            enabled = ${boolToStr settings.dates.enable},
          },
        }
      '';

    extraConfigLuaPost =
      #lua
      ''
        vim.cmd.cd(vim.fs.dirname("${settings.root}"))
        vim.cmd.edit("${settings.root}")
      '';

    globals.mapleader = settings.keys.leader;
    keymaps = [
      {
        key = settings.keys.map.followLink;
        action = "<cmd>NvnFollowLink<cr>";
      }
      {
        key = settings.keys.map.nextLink;
        action = "<cmd>NvnNextLink<cr>";
      }
      {
        key = settings.keys.map.previousLink;
        action = "<cmd>NvnPreviousLink<cr>";
      }
      {
        key = settings.keys.map.gotoPrevious;
        action = "<cmd>NvnGotoPrevious<cr>";
      }
      {
        key = settings.keys.map.deleteNote;
        action = "<cmd>NvnDeleteNote<cr>";
      }
      {
        key = settings.keys.map.createNote;
        action = "<cmd>NvnCreateNote<cr>";
      }
      {
        key = settings.keys.map.eval;
        action = "<cmd>NvnEval<cr>";
      }
      {
        key = settings.keys.map.openGraph;
        action = "<cmd>NvnOpenGraph<cr>";
      }
    ];
  };

  mkNvnWithoutDefaults =
    settings:
    pkgs.symlinkJoin {
      inherit name;
      paths = [
        (((nixvim.makeNixvim (import ../base-nvn-config.nix)).extend (mkPluginConfig settings)).extend (
          settings.extraSettings
        ))
      ];
      postBuild = ''
        rm -f $out/bin/nvim-python3 $out/bin/nixvim-print-init
        mv -f $out/bin/nvim $out/bin/${name}
      '';
    };

  # Provide default arguments
  mkNvnWithDefaults = makeOverridable mkNvnWithoutDefaults {
    root = (builtins.getEnv "HOME") + "/Documents/Notes/index.md";

    behaviour = {
      strictClosing = false;
      automaticCreation = false;
      autoSave = true;
    };

    appearance = {
      folding = true;
      hideNumbers = false;
    };

    templates = {
      enable = true;
      dir = "templates";
    };

    dates = {
      enable = true;
    };

    keys = {
      leader = " ";
      map = {
        createNote = "<leader>C";
        deleteNote = "<leader>D";
        eval = "<leader>E";
        followLink = "<CR>";
        gotoPrevious = "<Backspace>";
        nextLink = "<Tab>";
        openGraph = "<leader>O";
        previousLink = "<S-Tab>";
      };
    };

    extraSettings = { };
  };
in
{
  inherit mkPlugin mkNvnWithoutDefaults mkNvnWithDefaults;
}
