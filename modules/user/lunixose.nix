{
  den,
  lix,
  ...
}:
{
  den.aspects.lunixose = {
    includes =
      (with den.batteries; [
        define-user
        primary-user
        (user-shell "bash")
      ])
      ++ (with lix; [
        doomacs
        zenwser
        nixcord
        plasma
        hyprland
        kanata
      ]);
    nixos =
      { pkgs, ... }:
      {
      };

    homeManager =
      { pkgs, ... }:
      {
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
