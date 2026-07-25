{
  den.aspects.syncthing = {
    nixos = {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        user = "lunixose";
        dataDir = "/home/lunixose/.local/share/syncthing";
      };

      # Allow syncthing through the firewall.
      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPorts = [ 21027 ];
    };
  };
}
