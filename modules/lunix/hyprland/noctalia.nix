{ inputs, ... }:
{
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  lix.noctalia = {
    provides.to-hosts.nixos = {
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
    };
    homeManager = {
      imports = [
        inputs.noctalia.homeModules.default
      ];
      programs.noctalia = {
        enable = true;
        settings = {
          theme = {
            mode = "dark";
            source = "builtin";
            builtin = "Catppuccin";
          };
          wallpaper = {
            enabled = true;
            default.path = "/home/lunixose/Pictures/wallpaper/10.png";
          };
        };
      };
    };
  };
}
