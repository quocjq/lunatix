{ den, ... }:
{
  # user aspect
  den.aspects.lunixose = {
    includes =
      (with den.batteries; [
        batteries.define-user
        batteries.primary-user
        (batteries.user-shell "bash")
      ])
      ++ (with den.aspects; [
        aspects.settings
        aspects.doom-emacs
        aspects.zen-browser
        aspects.plasma
        aspects.nixcord
      ]);
    nixos =
      { pkgs, ... }:
      {
        users.users.lunixose = {
          description = "lunixose";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
          packages = [ ];
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.htop ];
      };

    # user can provide NixOS configurations
    # to any host it is included on
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
