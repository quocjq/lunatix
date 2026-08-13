{ inputs, ... }:

# Server layout (oracle): plain btrfs root + data, no LUKS (unencrypted VPS).
# Modeled on nix-community/disko example/simple-efi.nix with a /srv data part.
{
  den.aspects."disko-server" = {
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
              root = {
                priority = 2;
                label = "root";
                size = "40G";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  mountpoint = "/";
                };
              };
              data = {
                priority = 3;
                label = "data";
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  mountpoint = "/srv";
                };
              };
            };
          };
        };
      };
  };
}
