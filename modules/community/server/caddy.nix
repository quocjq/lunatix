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
                # Nuxt dashboard (SSR)
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
            # Private notes editor (login). Same Nuxt app, host-based routing.
            "note.lunixose.duckdns.org" = {
              extraConfig = ''
                reverse_proxy 127.0.0.1:3100
              '';
            };
          };
        };
      };
  };
}
