{ inputs, ... }:
{
  flake-file.inputs.nix-doom-emacs-unstraightened = {
    url = "github:marienz/nix-doom-emacs-unstraightened";
    inputs.nixpkgs.follows = "";
  };

  den.aspects.doom-emacs = {
    homeManager = {
      imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];

      programs.doom-emacs = {
        enable = true;
        doomDir = ../doomdir;
      };
    };
  };
}

