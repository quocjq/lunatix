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
          # tailnet URL (tailscale serve): https://oracle.taila425e1.ts.net
          hydraURL = "https://oracle.taila425e1.ts.net";
          port = 3001; # 3000 = forgejo, 3100 = blog, 3200 = homepage
          listenHost = "127.0.0.1"; # private; tailscale serve exposes it
          notificationSender = "hydra@lunixose.duckdns.org";
          # oracle has 26G free; pause the queue near-full so builds don't
          # starve the store alongside nixos-rebuild switches.
          minimumDiskFree = 20;
        };

        # Tailscale: oracle joins the tailnet; serve exposes hydra at
        # https://oracle.taila425e1.ts.net. The serve config is applied once at
        # runtime (tailnet-level "Enable Serve" toggle required):
        #   ssh oraclevps 'tailscale serve --bg 3001'
        # It persists in tailscaled state across reboots.
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "client";
        };
      };
  };
}
