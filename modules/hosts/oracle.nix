{ __findFile, ... }: {
  den.hosts.aarch64-linux.oracle = { };

  den.aspects.oracle = {
    includes = [
      <disko-layout>
      <lig/agenix>
      <locale>
      <nix-settings>
      <ssh>
      <syncthing-server>
      <pihole>
      <forgejo>
      <caddy>
      <duckdns>
    ];

    disk = {
      name = "main";
      device = "/dev/sda";
      layout = "server";
    };

    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      {
        system.stateVersion = "26.05";
        nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;

        # Oracle Cloud instances attach the boot volume over virtio. Ensure the
        # initrd carries the block + net drivers so the root device appears at
        # boot (without them: "start job running for /dev/disk/by-partlabel/root").
        boot.initrd.availableKernelModules = [
          "virtio_pci"
          "virtio_blk"
          "virtio_scsi"
          "virtio_net"
          "sd_mod"
          "btrfs"
        ];
        boot.initrd.kernelModules = [ "virtio_blk" ];
        boot.kernelParams = [ "console=tty0" "console=ttyAMA0,115200" "console=ttyS0,115200" ];

        # Headless server: networkd + DHCP instead of NetworkManager.
        networking.networkmanager.enable = lib.mkForce false;
        networking.useDHCP = lib.mkForce true;
        networking.firewall.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 80 443 ];

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkCjExNYxUFFr2joRL8Rq0jE/tEDfNR/hrKReH4FS9l lunixose"
        ];

        # Oracle rekeys secrets to its own host key. The pubkey lives in the
        # repo so rekey works before the box runs NixOS: capture it from the
        # current Ubuntu with `ssh-keyscan <ip> | grep ed25519`, then write it
        # to modules/community/lix/hardware/oracle.pub (first deploy uses
        # --copy-host-keys so the host key survives into the NixOS install).
        age.rekey.hostPubkey =
          if builtins.pathExists ../community/lix/hardware/oracle.pub then
            builtins.readFile ../community/lix/hardware/oracle.pub
          else
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI-placeholder-oracle";
      };
  };
}
