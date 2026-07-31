{ __findFile, ... }: {
  den.hosts.x86_64-linux.igloo.users.lunixose = { };

  den.aspects.igloo = {
    includes = [
      <settings>
      <latitude3250>
      <lig/agenix>
    ];
    nixos =
      {
        config,
        pkgs,
        lib,
        modulesPath,
        ...
      }:
      {
        hardware.facter.reportPath = ../hardware/latitude3250.json;
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;
      };
  };
}
