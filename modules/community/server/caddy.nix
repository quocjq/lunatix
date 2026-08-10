{
  server.caddy = {
    nixos =
      { ... }:
      {
        services.caddy = {
          enable = true;
          virtualHosts = {
            "lunixose.duckdns.org" = {
              extraConfig = ''
                # notes reader (login) + public blog
                handle {
                  reverse_proxy 127.0.0.1:3100
                }
              '';
            };
            "git.lunixose.duckdns.org" = {
              extraConfig = ''
                reverse_proxy 127.0.0.1:3000
              '';
            };
            "dns.lunixose.duckdns.org" = {
              extraConfig = ''
                reverse_proxy 127.0.0.1:8080
              '';
            };
          };
        };
      };
  };
}
