{ inputs, ... }: {
  flake-file.inputs = {
    nixcord = {
      url = "github:FlameFlag/nixcord";
    };
  };
  den.aspects.nixcord = {
    homeManager = { pkgs, ... }: {
      imports = [ inputs.nixcord.homeModules.nixcord ];

      programs.nixcord = {
        enable = true;

        # Choose your Discord mod client (enable at most one of these two)
        # discord.vencord.enable = true; # Standard Vencord
        discord.equicord.enable = true; # Equicord (has more plugins)

        # Or these
        # vesktop.enable = true;
        # dorion.enable = true;
        # legcord.enable = true;

        # Theming
        quickCss = "/* css goes here */";
        config = {
          useQuickCss = true;
          themeLinks = [
            "https://raw.githubusercontent.com/refact0r/midnight-discord/refs/heads/master/themes/midnight.theme.css"
          ];
          frameless = true;

          plugins = {
            hideMedia.enable = true;
            ignoreActivities = {
              enable = true;
              ignorePlaying = true;
              ignoredActivities = [
              ];
            };
          };
        };
      };
    };
  };
}
