{ ... }:
{
  den.aspects.settings = {
    nixos =
      { pkgs, config, ... }:
      {
        nixpkgs.config.allowUnfree = true;
        nix = {
          optimise.automatic = true;
          settings = {
            substituters = [

            ];
            trusted-public-keys = [

            ];
            experimental-features = [
              "nix-command"
              "flakes"
              "pipe-operators"
            ];
            trusted-users = [
              "root"
              "@wheel"
            ];
          };
          gc = pkgs.lib.optionalAttrs config.nix.enable {
            automatic = true;
            options = "--delete-older-than 3d";
          };
        };
      };
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        nixpkgs.config.allowUnfree = true;
      };
  };
}
