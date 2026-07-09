{
  den,
  lix,
  lig,
  ...
}:
{
  den.aspects.lunixose = {
    includes =
      (with den.batteries; [
        define-user
        primary-user
        (user-shell "bash")
        # custom-class
      ])
      ++ (with lix; [
        doomacs
        zenwser
        nixcord
        plasma
      ])
      ++ (with lig; [
        nixcord
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
