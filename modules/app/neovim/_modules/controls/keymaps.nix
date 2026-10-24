{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./clipboard.nix
  ];

  config.vim = {
    binds.whichKey.enable = true;

    binds.whichKey.register = {
      "<leader>a" = "AI (CodeCompanion)";
      "<leader>d" = "Debug (DAP)";
      "<leader>m" = "Markdown";
      "<leader>t" = "Terminal / Neo-tree / Theme";
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>.";
        action = "<cmd>Telescope find_files<CR>";
        desc = "Search for files in telescope";
      }
      {
        mode = "n";
        key = "<leader>tn";
        action = "<cmd>Neotree toggle<CR>";
        desc = "Open Neo-tree";
      }
      {
        mode = "n";
        key = "<leader>te";
        action = "<cmd>Neotree reveal<CR>";
        desc = "Reveal current file in Neo-tree";
      }
      {
        mode = "n";
        key = "<leader>th";
        action = "<cmd>ThemePicker<CR>";
        desc = "Theme picker";
      }
      {
        mode = "n";
        key = "<leader>td";
        action = "<cmd>ThemeDebug<CR>";
        desc = "Debug theme config location";
      }
      {
        mode = "n";
        key = "<leader>tr";
        action = "<cmd>ThemeReset<CR>";
        desc = "Reset theme to default";
      }
    ];
  };
}
