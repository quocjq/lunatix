{ inputs, ... }: {
  flake-file.inputs = {
    nixcord = {
      url = "github:4evy/nixcord";
    };
  };
  den.aspects.nixcord.default = {
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
        config = {
          useQuickCss = false;
          enabledThemeLinks = [
            "https://raw.githubusercontent.com/refact0r/midnight-discord/refs/heads/master/themes/midnight.theme.css"
          ];
          frameless = false;
          transparent = false;
        };
      };
    };
  };
}
