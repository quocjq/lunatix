{
  den.aspects.syncthing = {
    nixos = { user, ... }: {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        user = user.userName;
        dataDir = "/home/${user.userName}/Documents";
        settings = {
          devices = {
            oracle = {
              id = "JEDRDKP-ZNUZ45L-GQTTCVL-LJ23AYA-UV43N5A-AROU7J5-4B45GB2-LDJSEAE";
            };
          };
          folders = {
            notes = {
              path = "/home/${user.userName}/Documents/notes";
              devices = [ "oracle" ];
            };
          };
        };
      };

      # Allow syncthing through the firewall.
      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPorts = [ 21027 ];
    };
  };
}
