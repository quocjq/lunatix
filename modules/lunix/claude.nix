{
  lix.claude = {
    homeManager = { pkgs, ... }: {
      programs.claude-code = {
        enable = true;
        # Preserve the theme that was in the hand-written ~/.claude/settings.json
        # before home-manager took over the file.
        settings.theme = "dark";
        settings.statusLine = {
          type = "command";
          command = "${pkgs.starship}/bin/starship statusline claude-code";
          padding = 0;
        };
      };
    };
  };
}
