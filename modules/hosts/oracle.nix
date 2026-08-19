{ __findFile, ... }: {
  den.hosts.aarch64-linux.oracle = { };

  den.aspects.oracle = {
    includes = [
      <disko-server>
      <lig/agenix>
      <locale>
      <nix-settings>
      <ssh>
      <server/pihole>
      <server/forgejo>
      <server/caddy>
      <server/blog>
      <server/homepage>
      <server/duckdns>
      <server/syncthing-server>
      <server/forgejo-runner>
      <server/lunatix-deploy>
      <server/hydra>
      <server/vaultwarden>
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

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;

        # Hardware
        hardware.facter.reportPath = ../community/lix/hardware/oracle-facter.json;

        boot.kernelParams = [ "console=tty0" "console=ttyAMA0,115200" "console=ttyS0,115200" ];

        # Headless server: networkd + DHCP instead of NetworkManager.
        networking.networkmanager.enable = lib.mkForce false;
        networking.useDHCP = lib.mkForce true;
        networking.firewall.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 80 443 8222 ];

        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkCjExNYxUFFr2joRL8Rq0jE/tEDfNR/hrKReH4FS9l lunixose"
        ];

        #  Provide key for enter
        age.rekey.hostPubkey =
          if builtins.pathExists ../community/lix/hardware/oracle.pub then
            builtins.readFile ../community/lix/hardware/oracle.pub
          else
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI-placeholder-oracle";

        nix.settings = {
          max-jobs = 4;
        };
      };
  };
}
