{ inputs, ... }:
{
  den.aspects.latitude3250 = {
    nixos = {
      # imports = [
      #   inputs.nixos-facter-modules.nixosModules.facter
      # ];

      hardware.facter.reportPath = ./latitude3250.json;
    };
  };
}
