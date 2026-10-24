{
  config,
  pkgs,
  ...
}: {
  config.vim.languages.python = {
    enable = true;

    treesitter.enable = true;

    lsp.enable = true;

    format = {
      enable = true;
      type = ["ruff"];
    };

    dap = {
      enable = true;
      debugger = "debugpy";
      package = pkgs.python311.withPackages (ps: with ps; [ps.debugpy]);
    };
  };
}
