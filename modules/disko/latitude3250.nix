{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  #
  #   nvme0n1 (GPT)
  #   ├─ p1  1 GiB   EFI System                       vfat       -> /boot
  #   ├─ p2  ~228 G  LUKS2 -> btrfs                          -> / (top-level, subvolid=5)
  #   │                                                subvol home -> /home
  #   │                                                subvol nix  -> /nix
  #   └─ p3  rest    LUKS2 -> swap
  #
  # The two LUKS containers share one passphrase, so initrd only prompts once
  # (NixOS caches the entered passphrase and retries it on the swap device).
  #
  # NOTE: `/` is the btrfs top-level (subvolid=5), NOT a named subvolume — that
  # matches the current install. Disko expresses this with the `mountpoint` on
  # the btrfs content itself, alongside the two named subvolumes.
  #
  # `passwordFile` is read ONLY while formatting (disko/disko-install). Boot
  # still prompts interactively.
  #
  # Adopting this config on an EXISTING disk: p3 (swap) currently has no GPT
  # partlabel, so disko's partlabel-based LUKS resolution will not find it.
  # Before the first rebuild, run once (non-destructive, milliseconds):
  #
  #   sudo sgdisk -c 3:swap /dev/nvme0n1
  #   sudo partprobe /dev/nvme0n1
  #
  # Existing LUKS UUIDs persist — only the GPT name on p3 changes.
  den.aspects.disko-latitude3250 = {
    nixos = {
      imports = [ inputs.disko.nixosModules.disko ];
      disko.enableConfig = true;

      disko.devices = {
        disk.main = {
          type = "disk";
          # Stable, unique by-id path for this exact NVMe drive. Change this if
          # you deploy the layout to a different disk.
          device = "/dev/disk/by-id/nvme-eui.01000000000000008ce38e0402c27c5c";
          content = {
            type = "gpt";
            partitions = {
              # p1 — EFI System Partition. `label` pins the GPT partition name
              # to "EFI", matching the existing on-disk label so
              # /dev/disk/by-partlabel/EFI keeps resolving.
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

              # p2 — encrypted btrfs root.
              luks = {
                priority = 2;
                label = "root";
                size = "228G";
                content = {
                  type = "luks";
                  name = "luks-root";
                  # Passphrase source used ONLY while formatting (disko/disko-install).
                  # Create it first:  echo -n 'your-passphrase' > /tmp/secret.key
                  passwordFile = "/tmp/secret.key";
                  settings.allowDiscards = true;
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ];
                    # Named subvolumes. The btrfs top-level (subvolid=5) is
                    # mounted at "/" via the `mountpoint` below.
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

              # p3 — encrypted swap (fills the remaining space, ~8.8 GiB). `label`
              # pins the GPT partition name to "swap" so disko resolves p3 by
              # /dev/disk/by-partlabel/swap. Existing disks that lack this
              # label need a one-time `sgdisk -c 3:swap /dev/nvme0n1`.
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
  };
}
