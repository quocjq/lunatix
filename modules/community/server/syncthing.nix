{
  server.syncthing-server = {
    nixos = {
      services.syncthing = {
        enable = true;
        user = "root";
        group = "root";
        dataDir = "/root/.local/state/syncthing";
        configDir = "/root/.local/state/syncthing";
        openDefaultPorts = false;
        settings = {
          devices = {
            igloo = {
              id = "YTPKZIH-OJNM4JB-RE37WOY-DH5WZFN-X3LVJ2I-EF3SRSL-T62JQUP-Y5ESJAC";
            };
          };
          folders = {
            notes = {
              path = "/root/Notes";
              devices = [ "igloo" ];
            };
          };
        };
      };
      # Management UI only on localhost; devices reach the sync ports.
      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPorts = [ 21027 ];
    };
  };
}
