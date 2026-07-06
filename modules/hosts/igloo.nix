{ den, ... }: {
  den.hosts.x86_64-linux.igloo.users.lunixose = { };

  den.aspects.igloo = {
    includes = [
      den.aspects.settings
      den.aspects.latitude3250
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
        fileSystems."/" = {
          device = "/dev/mapper/luks-4775eff2-bc10-4918-8bb7-c64e35958085";
          fsType = "btrfs";
        };
        boot.initrd.luks.devices."luks-4775eff2-bc10-4918-8bb7-c64e35958085".device =
          "/dev/disk/by-uuid/4775eff2-bc10-4918-8bb7-c64e35958085";
        fileSystems."/home" = {
          device = "/dev/mapper/luks-4775eff2-bc10-4918-8bb7-c64e35958085";
          fsType = "btrfs";
          options = [ "subvol=home" ];
        };
        fileSystems."/nix" = {
          device = "/dev/mapper/luks-4775eff2-bc10-4918-8bb7-c64e35958085";
          fsType = "btrfs";
          options = [ "subvol=nix" ];
        };
        fileSystems."/boot" = {
          device = "/dev/disk/by-uuid/3E11-FD36";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
        swapDevices = [
          { device = "/dev/mapper/luks-1b8f30e4-ac2d-4ed1-b038-35cd76493e2a"; }
        ];
        boot.initrd.luks.devices."luks-1b8f30e4-ac2d-4ed1-b038-35cd76493e2a".device =
          "/dev/disk/by-uuid/1b8f30e4-ac2d-4ed1-b038-35cd76493e2a";
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;
        networking.hostName = "nixos";
      };
  };
}
