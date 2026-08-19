{ inputs, ... }:
{
  flake-file.inputs = {
    caelestia = {
      url = "github:caelestia-dots/shell";
    };
  };

  lix.caelestia = {
    os = { pkgs, ... }: {
      environment.systemPackages = [
        inputs.caelestia.packages.${pkgs.system}.with-cli
      ];
      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;
    };
  };
}
