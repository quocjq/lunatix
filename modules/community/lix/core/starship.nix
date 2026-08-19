{
  lix.starship = {
    os = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.starship ];
    };
    maid = {
      # Configuration written to ~/.config/starship.toml
      file.xdg_config."starship.toml".text = ''
        add_newline = false

        [character]
        success_symbol = "[➜](bold green)"
        error_symbol = "[➜](bold red)"

        # [package]
        # disabled = true
      '';
    };
  };
}
