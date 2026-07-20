{ ... }:
{
  den.aspects.nix-settings = {
    nixos =
      { pkgs, config, ... }:
      {
        nixpkgs.config.allowUnfree = true;

        # nh: the friendly nix-helper CLI. `flake` makes `nh os switch` (and
        # friends) default to this repo, so you can run nh from anywhere without
        # passing a path. Cleanup is driven manually from the justfile
        # (`just clean`), so nh's own scheduled clean stays off to avoid
        # colliding with nix.gc below.
        programs.nh = {
          enable = true;
          flake = "/home/lunixose/Proj/lunatix";
        };

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
