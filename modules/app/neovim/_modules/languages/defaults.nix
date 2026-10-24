{
  imports = [
    ./nix.nix
    ./rust.nix
    ./python.nix
    ./typescript-javascript.nix
  ];

  config.vim.lsp.enable = true;
}
