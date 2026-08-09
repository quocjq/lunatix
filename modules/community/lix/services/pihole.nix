{
  den.aspects.pihole = {
    nixos =
      { pkgs, ... }:
      {
        services.pihole-ftl = {
          enable = true;
          openFirewallDNS = true;
          settings = {
            dns = {
              "domain-needed" = true;
              "bogus-priv" = true;
            };
          };
        };
        services.pihole-web = {
          enable = true;
          hostName = "127.0.0.1";
          ports = [ 8080 ];
        };
      };
  };
}
