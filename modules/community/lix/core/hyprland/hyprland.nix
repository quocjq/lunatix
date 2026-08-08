{
  inputs,
  __findFile,
  ...
}:
{
  flake-file.inputs = {
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
  };

  lix.hyprland = {
    includes = [
      <lix/noctalia>
    ];
    provides.to-hosts.nixos = { pkgs, lib, ... }: {
      # The Hyprland Cachix exists to cache the hyprland packages and any dependencies not found in cache.nixos.org.
      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
        # Required so non-root users are allowed to use the above substituter/keys.
        # Use @wheel for all sudo users, or list your username explicitly.
        trusted-users = [
          "root"
          "@wheel"
        ];
      };

      programs.hyprland = {
        enable = true;
        withUWSM = false;
        xwayland.enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };

      services.accounts-daemon.enable = true;
      services.udisks2.enable = true;
      services.libinput.enable = lib.mkDefault true;
      services.geoclue2.enable = lib.mkDefault true;
      services.fwupd.enable = lib.mkDefault true;
      security.polkit.enable = true;
      programs.dconf.enable = true;
      programs.gnupg.agent.pinentryPackage = lib.mkDefault pkgs.pinentry-gnome3;
      xdg.icons.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
    };
    homeManager = {
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.configType = "lua";
    };
  };
}
