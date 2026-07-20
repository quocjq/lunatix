{
  lix.claude = {
    homeManager = { pkgs, ... }: {
      programs.claude-code = {
        enable = true;
        settings.statusLine = {
          type = "command";
          command = "${pkgs.starship}/bin/starship statusline claude-code";
          padding = 0;
        };
      };
    };
  };
}
