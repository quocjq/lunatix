# Tailscale: join the tailnet. Oracle enables it too (with serve for hydra)
# in modules/community/server/hydra.nix. Once `tailscale up` has authed a
# device, MagicDNS gives it a name from networking.hostName (igloo / oracle).
{
  den.aspects.tailscale = {
    nixos = {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
    };
  };
}
