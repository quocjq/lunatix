{
  server.hydra = {
    nixos =
      { pkgs, ... }:
      {
        # Hydra CI for the lunatix flake. Builds the aarch64 (oracle) outputs:
        # nixosConfiguration oracle toplevel + checks + packages. Private:
        # listens on loopback, exposed to the tailnet via tailscale serve.
        services.hydra = {
          enable = true;
          hydraURL = "http://oracle:3001";
          port = 3001; # 3000 = forgejo, 3100 = blog, 3200 = homepage
          listenHost = "127.0.0.1"; # private; tailscale serve exposes it
          notificationSender = "hydra@lunixose.duckdns.org";
          # oracle has 26G free; pause the queue near-full so builds don't
          # starve the store alongside nixos-rebuild switches.
          minimumDiskFree = 20;
        };

        # Tailscale: oracle joins the tailnet; serve forwards hydra to loopback.
        # MagicDNS name = "oracle" (from networking.hostName).
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          serve = {
            enable = true;
            services = {
              hydra = {
                endpoints = {
                  "tcp:3001" = "http://127.0.0.1:3001";
                };
              };
            };
          };
        };
      };
  };
}
