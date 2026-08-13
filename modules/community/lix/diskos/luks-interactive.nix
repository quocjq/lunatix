{ inputs, ... }:

# LUKS root with INTERACTIVE password entry (no keyfile — prompts on boot).
# Modeled on nix-community/disko example/luks-interactive-login.nix.
{
  den.aspects."disko-luks-interactive" = {
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
              luks = {
                priority = 2;
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  # No keyFile: cryptsetup prompts interactively at install
                  # and boot. (Remove this line's comment to use a keyfile.)
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    mountpoint = "/";
                  };
                };
              };
            };
          };
        };
      };
  };
}
