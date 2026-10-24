{config, ...}: {
  config.vim.autocmds = [
    # Nix formatting
    {
      event = ["BufWritePre"];
      pattern = ["*.nix"];
      command = "lua vim.lsp.buf.format()";
    }

    {
      event = ["BufWritePre"];
      pattern = ["*.py"];
      command = "lua vim.lsp.buf.format()";
    }

    {
      event = ["BufWritePre"];
      pattern = ["*.rs"];
      command = "lua vim.lsp.buf.format()";
    }

    {
      event = ["BufWritePre"];
      pattern = ["*.ts" "*.js" "*.tsx" "*.jsx"];
      command = "lua vim.lsp.buf.format()";
    }
  ];
}
