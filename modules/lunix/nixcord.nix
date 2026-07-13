{ inputs, ... }: {
  flake-file.inputs = {
    nixcord = {
      url = "github:4evy/nixcord";
    };
  };
  lix.nixcord = {
    homeManager = { pkgs, ... }: {
      imports = [ inputs.nixcord.homeModules.nixcord ];
      programs.nixcord = {
        enable = true;
        discord = {
          equicord.enable = true; # Equicord (has more plugins)
          branch = "stable";
          krisp.enable = true;
          openASAR.enable = true;
        };
        quickCss = "/* css goes here */";
        config = {
          useQuickCss = true;
          enabledThemeLinks = [
            "https://raw.githubusercontent.com/Catppuccin/discord/main/themes/mocha.theme.css"
          ];
          frameless = true;
          transparent = true;

          plugins = {
            clearUrls.enable = true;
            fakeProfileThemes.enable = true;
            noF1.enable = true;
            hideMedia.enable = true;
            ignoreActivities = {
              enable = true;
              ignorePlaying = true;
            };
          };
        };
      };
    };
  };
}
