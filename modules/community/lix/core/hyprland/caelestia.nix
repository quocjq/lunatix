{ inputs, ... }:
{
  flake-file.inputs = {
    caelestia = {
      url = "github:caelestia-dots/shell";
    };
  };

  lix.caelestia = {
    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          inputs.caelestia.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
          pkgs.quickshell
        ];

        services.upower.enable = true;
        services.power-profiles-daemon.enable = true;
      };
  };
}
