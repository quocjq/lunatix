{inputs, ...}: {
  lix.greetd = {
    os = {
      pkgs,
      user,
      ...
    }: {
      services.greetd = {
        enable = true;
        useTextGreeter = true;
        settings.default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --background doom --time --remember --remember-session --sessions  ${pkgs.hyprland}/share/wayland-sessions";
          user = "${user.userName}";
        };
      };
      environment.systemPackages = [
        pkgs.tuigreet
      ];
    };
  };
}
