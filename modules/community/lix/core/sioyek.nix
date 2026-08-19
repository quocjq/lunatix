{ __findFile, ... }: {
  lix.sioyek = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.sioyek ];
    };
    maid = {
      # keys_user.config = Zathura-style keybinds; prefs_user.config =
      # frozen catppuccin-mocha palette + startup commands (was stylix +
      # sioyek.nix `config`). Stylix sioyek target disabled (see stylix.nix).
      file.xdg_config."sioyek/keys_user.config".source = ./_config/.config/sioyek/keys_user.config;
      file.xdg_config."sioyek/prefs_user.config".source = ./_config/.config/sioyek/prefs_user.config;
    };
  };
}
