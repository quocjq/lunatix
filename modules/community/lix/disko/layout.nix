{ inputs, ... }:
{
  den.quirks.disk = {
    description = "Per-host disk declaration: name + device";
  };

  den.aspects.disko-layout = {
    nixos =
      { disk, ... }:
      let
        disk0 = builtins.head disk;
      in
      {
        imports = [ inputs.disko.nixosModules.disko ];
        disko.enableConfig = true;

        disko.devices.disk.${disk0.name} = {
          type = "disk";
          device = disk0.device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                label = "EFI";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0077"
                    "dmask=0077"
                  ];
                };
              };
              luks = {
                priority = 2;
                label = "root";
                size = "228G";
                content = {
                  type = "luks";
                  name = "luks-root";
                  passwordFile = "/tmp/secret.key";
                  settings.allowDiscards = true;
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    subvolumes = {
                      "/home" = {
                        mountpoint = "/home";
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                      };
                    };
                    mountpoint = "/";
                  };
                };
              };
              swap = {
                priority = 3;
                label = "swap";
                size = "100%";
                content = {
                  type = "luks";
                  name = "luks-swap";
                  passwordFile = "/tmp/secret.key";
                  settings.allowDiscards = true;
                  content = {
                    type = "swap";
                  };
                };
              };
            };
          };
        };
      };
  };
}
