{ __findFile, ... }: {
  den.hosts.x86_64-linux.igloo.users.lunixose = { };

  den.aspects.igloo = {
    includes = [
      <settings>
      <disko-layout>
      <lig/agenix>
    ];

    disk = {
      name = "main";
      device = "/dev/disk/by-id/nvme-eui.01000000000000008ce38e0402c27c5c";
    };

    nixos =
      {
        config,
        pkgs,
        lib,
        modulesPath,
        ...
      }:
      {
        hardware.facter.reportPath = ../community/lix/hardware/latitude3250.json;
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;
        age.rekey.hostPubkey = "/etc/ssh/ssh_host_ed25519_key.pub";
      };
  };
}
