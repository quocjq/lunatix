{
  den.aspects.duckdns = {
    secrets = [
      {
        name = "duckdns-token";
        path = "/run/duckdns/token";
        owner = "root";
        group = "root";
        mode = "0400";
      }
    ];

    nixos =
      { ... }:
      {
        services.duckdns = {
          enable = true;
          # Only the primary domain is registered in the DuckDNS account;
          # subdomains (dns., git.) resolve via DuckDNS wildcard to the same
          # static IP, so no per-subdomain update is needed.
          domains = [ "lunixose" ];
          tokenFile = "/run/duckdns/token";
        };
      };
  };
}
