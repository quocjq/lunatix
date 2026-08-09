{
  den.aspects.caddy = {
    nixos =
      { pkgs, ... }:
      {
        services.caddy = {
          enable = true;
          virtualHosts."http://localhost" = {
            extraConfig = ''
              respond "lunatix oracle online"
            '';
          };
        };
      };
  };
}
