{ den, ... }:
{
  den.aspects.lunixose = {
    includes =
      (with den.batteries; [
        batteries.define-user
        batteries.primary-user
        (batteries.user-shell "bash")
      ])
      ++ (with den.aspects; [
        aspects.settings
        aspects.doomacs
        aspects.zenwser
        aspects.nixcord
        aspects.plasma
      ]);
    nixos =
      { pkgs, ... }:
      {
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.htop ];
      };

    provides.to-hosts.nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        neovim
        wget
        git
        curl
        obsidian
      ];
    };
  };
}
