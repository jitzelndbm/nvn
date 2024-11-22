{
  pkgs,
  settings,
  plugin,
}:
let
  inherit (pkgs.lib) concatLines;
  inherit (pkgs.neovimUtils) makeNeovimConfig;

  setup = plugin: opts: "require('${plugin}').setup({${opts}})";

  toLua = x: ''
    lua << END
    	${x}
    END
  '';

  nmap = key: cmd: "vim.keymap.set('n', '${key}', '${cmd}')";
in
makeNeovimConfig {
  withPython3 = false;
  withNodeJs = false;
  withRuby = false;

  pname = "nvn";

  luaRcContent =
    let
      inherit (settings) extraOpts keymaps;
    in
    (concatLines [
      # lua
      ''
        vim.g.mapleader = '${keymaps.leader}' 
      ''
      extraOpts
    ]);

  plugins =
    let
      inherit (pkgs.vimPlugins) mini-nvim nvim-treesitter base16-nvim;
      inherit (settings) extraPlugins;
    in
    extraPlugins
    ++ [
      (
        let
          inherit (settings)
            keymaps
            root
            index
            autoEvaluation
            autoSave
            handlers
            templateFolder
            ;
        in
        {
          inherit plugin;
          config =
            let
              boolToStr = x: if x then "true" else "false";
              handlersTable =
                "{"
                + (concatLines (
                  map (x: ''
                    {
                    	pattern = "${x.pattern}",
                    	handler = function (client, link)
                    		${x.handler}
                    	end
                    },
                  '') handlers
                ))
                + "}";
            in
            toLua (concatLines [
              # Normal configuration
              (setup "nvn" ''
                root = "${root}",
                index = "${index}",
                auto_evaluation = ${boolToStr autoEvaluation},
                auto_save = ${boolToStr autoSave},
                template_folder = ${templateFolder},
                handlers = ${handlersTable},
              '')

              # Keymaps
              (nmap keymaps.followLink "<cmd>NvnFollowLink<cr>")
              (nmap keymaps.nextLink "<cmd>NvnNextLink<cr>")
              (nmap keymaps.previousLink "<cmd>NvnPreviousLink<cr>")
              (nmap keymaps.gotoPrevious "<cmd>NvnGotoPrevious<cr>")
              (nmap keymaps.deleteNote "<cmd>NvnDeleteNote<cr>")
              (nmap keymaps.createNote "<cmd>NvnCreateNote<cr>")
              (nmap keymaps.eval "<cmd>NvnEval<cr>")
              (nmap keymaps.openGraph "<cmd>NvnOpenGraph<cr>")
            ]);
        }
      )

      {
        plugin = mini-nvim;
        config = toLua (concatLines [
          (setup "mini.pick" "")
          (setup "mini.notify" "")
          "vim.notify = MiniNotify.make_notify()"
        ]);
      }

      {
        plugin = nvim-treesitter.withPlugins (p: [
          p.markdown
          p.markdown_inline
          p.lua
        ]);
        config = toLua (setup "nvim-treesitter.configs" "highlight = { enable = true }");
      }

      (
        let
          inherit (settings.colors)
            base00
            base01
            base02
            base03
            base04
            base05
            base06
            base07
            base08
            base09
            base0A
            base0B
            base0C
            base0D
            base0E
            base0F
            ;
        in
        {
          plugin = base16-nvim;
          config = toLua (
            setup "base16-colorscheme" ''
              base00 = "${base00}",
              base01 = "${base01}",
              base02 = "${base02}",
              base03 = "${base03}",
              base04 = "${base04}",
              base05 = "${base05}",
              base06 = "${base06}",
              base07 = "${base07}",
              base08 = "${base08}",
              base09 = "${base09}",
              base0A = "${base0A}",
              base0B = "${base0B}",
              base0C = "${base0C}",
              base0D = "${base0D}",
              base0E = "${base0E}",
              base0F = "${base0F}"
            ''
          );
        }
      )
    ];
}
