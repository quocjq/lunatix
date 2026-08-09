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
      { pkgs, ... }:
      {
        services.duckdns = {
          enable = true;
          domains = [ "lunixose" ];
          tokenFile = "/run/duckdns/token";
        };
        # DuckDNS updater needs curl at runtime.
        systemd.services.duckdns = {
          path = [ pkgs.curl ];
        };
      };
  };
}
