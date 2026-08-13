{ inputs, ... }:

# tmpfs-on-root: / is tmpfs (RAM, lost on reboot), ESP on disk. Minimal,
# ephemeral — good for test VMs. Modeled on
# nix-community/disko example/tmpfs.nix.
{
  den.aspects."disko-tmpfs-root" = {
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
                size = "100%";
                content = {
                  type = "tmpfs";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
  };
}
