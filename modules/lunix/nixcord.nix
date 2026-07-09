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
      };
    };
  };
}
