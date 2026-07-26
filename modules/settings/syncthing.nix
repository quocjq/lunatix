{
  den.aspects.syncthing = {
    nixos = { user, ... }: {
      services.syncthing = {
        enable = true;
        openDefaultPorts = true;
        user = user.userName;
        dataDir = "/home/${user.userName}/Documents";
      };

      # Allow syncthing through the firewall.
      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPorts = [ 21027 ];
    };
  };
}
