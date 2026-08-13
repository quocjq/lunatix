{ inputs, ... }:

# ESP + root + a dedicated (unencrypted) swap partition. Modeled on
# nix-community/disko example/swap.nix.
{
  den.aspects."disko-swap" = {
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
                size = "500M";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "fmask=0077" "dmask=0077" ];
                };
              };
              root = {
                priority = 2;
                size = "40G";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
              swap = {
                priority = 3;
                size = "100%";
                content = {
                  type = "swap";
                };
              };
            };
          };
        };
      };
  };
}
