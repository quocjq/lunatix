{
  config,
  pkgs,
  ...
}: {
  config.vim.languages.nix = {
    enable = true;

    treesitter.enable = true;

    lsp.enable = true;

    format = {
      enable = true;
      type = ["alejandra"];
    };
  };
}
