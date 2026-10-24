{config, ...}: {
  imports = [
    ./controls/keymaps.nix
    ./languages/defaults.nix
    ./plugins/defaults.nix
    ./ui/defaults.nix
  ];
  config.vim.options = {
    number = true;
    relativenumber = false;
  };
}
