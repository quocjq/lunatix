{
  den.aspects.network = {
    nixos = {
      networking.networkmanager.enable = true;

      # Delegate DNS to systemd-resolved; NetworkManager forwards queries.
      services.resolved = {
        enable = true;
        fallbackDns = [ "1.1.1.1" ];
        dnsssec = "true";
      };
      networking.networkmanager.dns = "systemd-resolved";
    };
  };
}
