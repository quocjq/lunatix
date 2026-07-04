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
        discord = {
          # equicord.enable = true; # Equicord (has more plugins)
          legcord.enable = true;
          branch = "stable";
          krisp.enable = true;
          openASAR.enable = true;
        };

        # Or these
        # vesktop.enable = true;
        # dorion.enable = true;

        # Theming
        # quickCss = "/* css goes here */";
        config = {
          useQuickCss = false;
          enabledThemeLinks = [
            "https://raw.githubusercontent.com/refact0r/midnight-discord/refs/heads/master/themes/midnight.theme.css"
          ];
          frameless = true;
          # transparent = true;

          plugins = {
            clearUrls.enable = true;
            fakeProfileThemes.enable = true;
            noF1.enable = true;
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
