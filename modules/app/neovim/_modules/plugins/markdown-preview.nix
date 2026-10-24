{ pkgs, ... }: {
  config.vim.utility.preview.markdownPreview = {
    enable = true;
    autoStart = false;

    autoClose = false;
  };

  config.vim.globals = {
    mkdp_combine_preview = 1;
    mkdp_combine_preview_auto_refresh = 1;
  };

  config.vim.extraPackages = [ pkgs.nodejs ];

  config.vim.keymaps = [
    {
      mode = "n";
      key = "<leader>mp";
      action = "<cmd>MarkdownPreviewToggle<CR>";
      desc = "Toggle Markdown preview (browser)";
    }
  ];
}
