{ ... }:
{
  lix.greetd = {
    provides.to-hosts.nixos =
      { pkgs, ... }:
      {
        services.greetd = {
          enable = true;
          useTextGreeter = true;
          settings.default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --sessions /run/current-system/sw/share/xsessions:/run/current-system/sw/share/wayland-sessions";
            user = "lunixose";
          };
        };
        # tuigreet is not a service package in pinned nixpkgs; expose on PATH.
        environment.systemPackages = [ pkgs.tuigreet ];
        # SDDM must not coexist with greetd.
        services.displayManager.sddm.enable = false;
      };
  };
}
