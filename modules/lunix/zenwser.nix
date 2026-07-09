{ inputs, ... }:
{
  flake-file.inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  lix.zenwser = {
    homeManager = {
      imports = [ inputs.zen-browser.homeModules.twilight ];
      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
      };
    };

  };
}
