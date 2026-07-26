{
  den.aspects.network = {
    nixos = {
      networking.networkmanager.enable = true;
      networking.nameservers = [
        "1.1.1.1#one.one.one.one"
        "1.0.0.1#one.one.one.one"
      ];
      # Delegate DNS to systemd-resolved; NetworkManager forwards queries.
      services.resolved = {
        enable = true;
        settings.Resolve = {
          DNS = [ "1.1.1.1" ];
          Domains = [ "~." ];
          DNSOverTLS = "true";
          FallbackDNS = [ "1.1.1.1" ];
          DNSSEC = "true";
        };
      };
      networking.networkmanager.dns = "systemd-resolved";
    };
  };
}
