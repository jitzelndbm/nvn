{
  #################################################################
  # PLUGINS #######################################################
  #################################################################
  plugins.treesitter = {
    enable = true;
    settings = {
      highlight.enable = true;
      indent.enable = true;
      ensure_installed = [
        "markdown"
        "markdown_inline"
      ];
    };
  };
  plugins.luasnip.enable = true;
  plugins.transparent.enable = true;
  plugins.mini = {
    enable = true;
    modules = {
      pick = { };
    };
  };
  plugins.fidget = {
    enable = true;
    notification.overrideVimNotify = true;
    logger.level = "trace";
  };

  colorschemes.base16 = {
    enable = true;
    colorscheme = "classic-dark";
  };

  plugins.cmp_luasnip.enable = true;
  plugins.cmp = {
    enable = true;
    autoEnableSources = true;
    settings = {
      sources = [
        { name = "path"; }
        { name = "luasnip"; }
      ];
      mapping = {
        "<CR>" = "cmp.mapping.confirm({ select = true })";
        "<C-Space>" = "cmp.mapping.complete()";
        "<C-d>" = "cmp.mapping.scroll_docs(-4)";
        "<C-e>" = "cmp.mapping.close()";
        "<C-f>" = "cmp.mapping.scroll_docs(4)";
        "<S-Tab>" = ''
          cmp.mapping(function(fallback)
             local luasnip = require("luasnip")
             if cmp.visible() then
               cmp.select_prev_item()
             elseif luasnip.locally_jumpable(-1) then
               luasnip.jump(-1)
             else
               fallback()
             end
          end, { 'i', 's' })
        '';
        "<Tab>" = ''
          cmp.mapping(function(fallback)
            local luasnip = require("luasnip")
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' })
        '';
      };
      snippet.expand = ''
        function(args)
          require('luasnip').lsp_expand(args.body)
        end
      '';
    };
  };

  #################################################################
  # AUTO CMD ######################################################
  #################################################################
  autoCmd = [
    {
      event = [
        "BufEnter"
        "BufWinEnter"
      ];
      command = "set syntax=markdown";
      pattern = "*.md";
    }
  ];
}
