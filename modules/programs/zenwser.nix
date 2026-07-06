{ inputs, ... }:
{
  flake-file.inputs.zenwser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.zen-browser = {
    homeManager = {
      imports = [ inputs.zen-browser.homeModules.twilight ];
      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
      };
    };

  };
}
