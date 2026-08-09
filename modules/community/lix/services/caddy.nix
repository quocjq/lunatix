{
  den.aspects.caddy = {
    nixos =
      { ... }:
      {
        services.caddy = {
          enable = true;
          virtualHosts."lunixose.duckdns.org" = {
            extraConfig = ''
              handle {
                respond "lunatix oracle online"
              }
              handle_path /forgejo/* {
                reverse_proxy 127.0.0.1:3000
              }
              handle_path /pihole/* {
                reverse_proxy 127.0.0.1:8080
              }
            '';
          };
        };
      };
  };
}
