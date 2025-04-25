_: {
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
    stylua.enable = true;
  };

  settings.formatter.stylua = {
    quote_style = "AutoPreferDouble";
    call_parentheses = "Always";
    collapse_simple_statement = "Always";
    column_width = 80;
  };
}
