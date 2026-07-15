{ inputs, ... }:
{
  flake-file.inputs.noctalia = {
    url = "github:noctalia-dev/noctalia";
    inputs.nixpkgs.follow = "nixpkgs";
  };

  lix.noctalia = {
    provides.to-hosts.nixos = {
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
    };
    homeManager = {
      home-manager.users.drfoobar = {
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
              enabled = false;
              default.path = "/path/to/wallpapers/wallpaper.png";
            };
          };
        };
      };
    };
  };
}
