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

  defaultNvnSettings = {
    root = "/home/jitze/dx/notes/index.md";
    #root = (builtins.getEnv "HOME") + "/Documents/Notes/index.md";

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

  mkNvnWithDefaults = makeOverridable mkNvnWithoutDefaults defaultNvnSettings;

  mkNvnWithoutDefaultsFast =
    settings:
    pkgs.neovim.override {
      withPython3 = false;
      configure = {
        customRC =
          #vim
          ''
            let g:mapleader="${settings.keys.leader}"

            set conceallevel=2

            lua << END
              vim.keymap.set('n', "${settings.keys.map.createNote}", "<cmd>NvnCreateNote<CR>")
              vim.keymap.set('n', "${settings.keys.map.deleteNote}", "<cmd>NvnDeleteNote<CR>")
              vim.keymap.set('n', "${settings.keys.map.eval}", "<cmd>NvnEval<CR>")
              vim.keymap.set('n', "${settings.keys.map.followLink}", "<cmd>NvnFollowLink<CR>")
              vim.keymap.set('n', "${settings.keys.map.gotoPrevious}", "<cmd>NvnGotoPrevious<CR>")
              vim.keymap.set('n', "${settings.keys.map.nextLink}", "<cmd>NvnNextLink<CR>")
              vim.keymap.set('n', "${settings.keys.map.openGraph}", "<cmd>NvnOpenGraph<CR>")
              vim.keymap.set('n', "${settings.keys.map.previousLink}", "<cmd>NvnPreviousLink<CR>")
            END
          '';
        packages.a.start = [
          pkgs.vimPlugins.transparent-nvim
          pkgs.vimPlugins.cmp_luasnip
          pkgs.vimPlugins.luasnip
          {
            plugin = pkgs.vimPlugins.nvim-cmp;
            config =
              #vim
              ''
                  lua << END
                  local cmp = require'cmp'
                  local luasnip = require"luasnip"
                  vim.opt.completeopt = {'menu', 'preview'}
                  cmp.setup {
                    snippet = {
                      expand = function(args)
                        luasnip.lsp_expand(args.body)
                      end,
                    },

                    sources = cmp.config.sources { 
                      { name = "luasnip" },
                      { name = "path" }  
                    },

                    mapping = {
                      ["<C-Space>"] = cmp.mapping.complete(),
                      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                      ["<C-e>"] = cmp.mapping.abort(),
                      ["<C-f>"] = cmp.mapping.scroll_docs(4),
                      ['<CR>'] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                          if luasnip.expandable() then
                            luasnip.expand()
                          else
                            cmp.confirm({
                              select = true,
                            })
                          end
                        else
                          fallback()
                        end
                      end),

                      ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                          cmp.select_next_item()
                        elseif luasnip.locally_jumpable(1) then
                          luasnip.jump(1)
                        else
                          fallback()
                        end
                      end, { "i", "s" }),

                      ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                          cmp.select_prev_item()
                        elseif luasnip.locally_jumpable(-1) then
                          luasnip.jump(-1)
                        else
                          fallback()
                        end
                      end, { "i", "s" }),,
                              }
                  }
                END
              '';
          }
          {
            plugin = pkgs.vimPlugins.fidget-nvim;
            config =
              #vim
              ''
                lua << END
                  require("fidget").setup {
                    logger = { level = vim.log.levels.TRACE },
                    notification = { override_vim_notify = true },
                  }
                END
              '';
          }
          {
            plugin = pkgs.vimPlugins.base16-nvim;
            config =
              #vim
              ''
                colorscheme base16-default-dark
              '';
          }
          {
            plugin = pkgs.vimPlugins.mini-nvim;
            config =
              #vim
              ''
                lua << END
                  require'mini.pick'.setup()
                END
              '';
          }
          {
            plugin = pkgs.vimPlugins.nvim-treesitter.withPlugins (
              p: with p; [
                lua
                markdown
                markdown_inline
              ]
            );
            config =
              #vim
              ''
                lua << END
                  require'nvim-treesitter.configs'.setup {
                    highlight = { enable = true },
                    indent = { enable = true },
                  }  
                END
              '';
          }
          {
            plugin = mkPlugin;
            config =
              #vim
              ''
                lua << END
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
                END
              '';
          }
        ];
      };
    };

  mkNvnWithDefaultsFast = makeOverridable mkNvnWithoutDefaultsFast defaultNvnSettings;
in
{
  inherit
    mkPlugin
    mkNvnWithoutDefaults
    mkNvnWithDefaults
    mkNvnWithoutDefaultsFast
    mkNvnWithDefaultsFast
    ;
}
