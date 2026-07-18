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
      ])
      ++ (with lix; [
        doomacs
        zenwser
        nixcord
        plasma
        hyprland
        kanata
      ]);

    provides.to-hosts.nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        yazi
        ghostty
        neovim
        wget
        git
        curl
        obsidian
      ];
    };
  };
}
