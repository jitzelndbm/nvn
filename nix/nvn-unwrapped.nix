{
  plugin,
  wrapNeovimUnstable,
  neovim-unwrapped,
  vimPlugins,
  neovimUtils,
  lib,
}:
settings:
(wrapNeovimUnstable neovim-unwrapped (
  import ./config.nix {
    inherit settings plugin;
    inherit (lib) concatLines;
    inherit (vimPlugins) mini-nvim nvim-treesitter base16-nvim;
    inherit (neovimUtils) makeNeovimConfig;
  }
)).overrideAttrs
  (old: {
    postInstall = ''
      mv $out/bin/nvim $out/bin/.nvn-wrapped
      touch $out/bin/nvn
      chmod +x $out/bin/nvn
      echo -e "#!/usr/bin/env bash\nexec $out/bin/.nvn-wrapped "${settings.root}/${settings.index}"" > $out/bin/nvn
    '';
  })
