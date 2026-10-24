{
  den.aspects.nix-settings = {
    nixos =
      { pkgs, config, ... }:
      {
        nixpkgs.config.allowUnfree = true;

        programs.nh = {
          enable = true;
          flake = toString ./../../../..;
        };

        nix = {
          optimise.automatic = true;
          settings = {
            substituters = [
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
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
    # The HM tail (nixcord, emacs...) still runs on the homeManager class; HM
    # evaluates packages with its own nixpkgs.config, so allowUnfree must be
    # set there too until the tail is gone.
    # provides.to-users.homeManager =
    #   { pkgs, ... }:
    #   {
    #     nixpkgs.config.allowUnfree = true;
    #   };
  };
}
