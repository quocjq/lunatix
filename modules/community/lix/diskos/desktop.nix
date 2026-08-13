# Desktop layout (igloo): LUKS root + btrfs /home /nix subvolumes + LUKS swap.
# Modeled on nix-community/disko example/luks-btrfs-subvolumes.nix
# + a separate encrypted swap partition.
{
  inputs,
  ...
}:
{
  den.aspects."disko-desktop" = {
    nixos =
      { disk, ... }:
      let
        d = builtins.head disk;
      in
      {
        imports = [ inputs.disko.nixosModules.disko ];
        disko.enableConfig = true;
        disko.devices.disk.${d.name} = {
          type = "disk";
          device = d.device;
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
                        mountOptions = [ "compress=zstd" "noatime" ];
                      };
                      "/nix" = {
                        mountpoint = "/nix";
                        mountOptions = [ "compress=zstd" "noatime" ];
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
