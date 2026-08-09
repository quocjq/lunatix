{
  den.aspects.syncthing-server = {
    nixos = {
      services.syncthing = {
        enable = true;
        user = "syncthing";
        group = "syncthing";
        dataDir = "/srv/syncthing";
        configDir = "/srv/syncthing/.config/syncthing";
        openDefaultPorts = false;
      };
      # Management UI only on localhost; devices reach the sync ports.
      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPorts = [ 21027 ];
    };
  };
}
