{ inputs, lix, ... }:
{
  flake-file.inputs = {
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
  };

  lix.hyprland = {
    includes = [
      lix.noctalia
    ];
    # Requirement
    provides.to-hosts.nixos = { pkgs, ... }: {
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
    };
    homeManager = {
      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.configType = "lua";
    };

    # Will replace home-manager with maid soon!
    #maid = {};
  };
}
