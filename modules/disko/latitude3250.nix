{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Disko declaration mirroring the hand-made layout on the Latitude 3250's
  # 256 GB KIOXIA NVMe drive:
  #
  #   nvme0n1 (GPT)
  #   ├─ p1  1 GiB   EFI System                       vfat  -> /boot
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
  den.aspects.disko-latitude3250 = {
    nixos = {
      imports = [ inputs.disko.nixosModules.disko ];

      # Reinstall-only mode: declare the layout for `disko` to format a fresh
      # disk, but do NOT let disko generate this system's fileSystems/luks/swap.
      # The running igloo keeps the hand-written mounts in modules/hosts/igloo.nix,
      # so activating this module never affects the current boot. Flip to `true`
      # (and drop the manual block in igloo.nix) only on a clean install where the
      # disk was partitioned by `disko` itself.
      disko.enableConfig = false;

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

              # p2 — encrypted btrfs root. GPT label pinned to "root" to match
              # the existing partition.
              luks = {
                priority = 2;
                label = "root";
                size = "228G";
                content = {
                  type = "luks";
                  name = "luks-root";
                  # Passphrase source used ONLY while formatting (disko/disko-install).
                  # Create it first:  echo -n 'your-passphrase' > /tmp/secret.key
                  # It is not referenced at boot; boot prompts interactively.
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

              # p3 — encrypted swap (fills the remaining space, ~8.8 GiB)
              swap = {
                priority = 3;
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
