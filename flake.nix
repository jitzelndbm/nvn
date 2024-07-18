{
  description = ''
    A Neovim plugin for taking notes. With Nix it can become a full fledged Neovim distribution!
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    dnc.url = "https://linsoft.nl/git/jitze/default-nixvim-config/archive/master.tar.gz";
  };

  outputs = {
    self,
    nixpkgs,
    dnc,
    nixvim,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      name = "nvn";
      pkgs = import nixpkgs {inherit system;};
      plugin = pkgs.vimUtils.buildVimPlugin {
        inherit name;
        src = self;
      };
    in {
      packages.plugin = plugin;

      packages.default = nixvim.legacyPackages.${system}.makeNixvim {
        plugins.treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
            ensure_installed = ["markdown" "markdown_inline"];
          };
        };
        plugins.transparent.enable = true;
        plugins.mini = {
          enable = true;
          modules = {
            notify = {};
          };
        };
        colorschemes.base16 = {
          enable = true;
          colorscheme = "classic-dark";
        };
        plugins.cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            sources = [
              {name = "path";}
            ];
            mapping = {
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-e>" = "cmp.mapping.close()";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<S-Tab>" = ''
                cmp.mapping(function(fallback)
                   if cmp.visible() then
                       cmp.select_prev_item()
                   else
                       fallback()
                   end
                end, { 'i', 's' })
              '';
              "<Tab>" = ''
                cmp.mapping(function(fallback)
                   if cmp.visible() then
                       cmp.select_next_item()
                   else
                       fallback()
                   end
                end, { 'i', 's' })
              '';
            };
          };
        };

        opts = {
          conceallevel = 2;
          number = false;
          relativenumber = false;
          foldmethod = "expr";
          foldexpr = "nvim_treesitter#foldexpr()";
          foldlevel = 2;
        };

        autoCmd = [
          {
            event = ["BufEnter" "BufWinEnter"];
            command = "set syntax=markdown";
            pattern = "*.md";
          }
        ];

        extraPlugins = [plugin];
        extraConfigLuaPost =
          #lua
          ''
            vim.cmd.cd(vim.fs.dirname(root))
            vim.cmd.edit(root)
          '';
        extraConfigLua =
          #lua
          ''
            local root = os.getenv("HOME") .. "/dx/notes/index.md"

            local notify = require('mini.notify')
            notify.setup{}
            vim.notify = notify.make_notify {}

            require'nvn'.setup {
              root = root,

              behaviour = {
                  -- :wqa should be used to safely close notes, enforce it.
                  strict_closing = false,

                  -- When a link is pressed and the file does not exist, create it
                  automatic_creation = false,
              },

              appearance = {
                -- Enable markdown header folding
                folding = true,
              },

              templates = {
                -- Wheter to enable templates or not
                enabled = true,

                -- Directory where templates are stored
                dir = "templates"
              },

              dates = {
                -- Whether to enable date formatting
                enabled = true,
              },
            }

          '';

        globals.mapleader = " ";
        keymaps = [
          {
            key = "<CR>";
            action = "<cmd>NvnFollowLink<cr>";
          }
          {
            key = "<Tab>";
            action = "<cmd>NvnNextLink<cr>";
          }
          {
            key = "<S-Tab>";
            action = "<cmd>NvnPreviousLink<cr>";
          }
          {
            key = "<Backspace>";
            action = "<cmd>NvnGotoPrevious<cr>";
          }
          {
            key = "<leader>D";
            action = "<cmd>NvnDeleteNote<cr>";
          }
          {
            key = "<leader>C";
            action = "<cmd>NvnCreateNote<cr>";
          }
        ];
      };

      devShells.default = let
        default_config = nixvim.legacyPackages.${system}.makeNixvim dnc.config;
        nvim = default_config.extend ({helpers, ...}: {
          extraConfigLua =
            #lua
            ''
              	require'lspconfig'.lua_ls.setup({
              		settings = {
              			Lua = {
              				diagnostics = {
              					globals = { "vim", "require" },
              				},
              				workspace = {
              					library = vim.api.nvim_get_runtime_file("", true),
              				},
              				telemetry = {
              					enable = false,
              				},
              			},
              		},
              });
            '';
          plugins = {
            treesitter.settings.ensure_installed = ["lua"];
            lsp.servers.lua-ls.enable = true;
            conform-nvim = {
              formattersByFt = {
                lua = ["stylua"];
              };
            };
          };
        });
      in
        pkgs.mkShell {
          buildInputs = with pkgs;
            [
              luajit
              stylua
              lua-language-server
            ]
            ++ [nvim];

          shellHook =
            #sh
            ''
              exec $SHELL
            '';
        };
    });
}
