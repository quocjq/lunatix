{ den, ... }:
{
  # user aspect
  den.aspects.lunixose = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      (den.batteries.user-shell "bash")
      den.aspects.settings
      den.aspects.doom-emacs
      den.aspects.zen-browser
      den.aspects.plasma
      den.aspects.nixcord
    ];
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
