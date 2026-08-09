{
  den.aspects.caddy = {
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
                # Forgejo
                handle_path /forgejo/* {
                  reverse_proxy 127.0.0.1:3000
                }
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
