{ __findFile, inputs, ... }: {
  den.hosts.x86_64-linux.igloo.users.lunixose = { };

  den.aspects.igloo = {
    includes = [
      <settings>
      <disko-desktop>
      <lig/agenix>
      <obs>
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
        # igloo builds on itself: derivation mode keeps rekeyed secrets out of
        # the repo (avoids the localStorageDir store-path write issue).
        age.rekey.storageMode = "derivation";

        nix.settings = {
          max-jobs = 1;
          cores = 2;
        };

        # nix-maid: user dotfiles are routed via the lix.* maid class into
        # users.users.<user>.maid; the den maid battery auto-imports the
        # nix-maid NixOS module when a user carries the "maid" class.
      };
  };
}
