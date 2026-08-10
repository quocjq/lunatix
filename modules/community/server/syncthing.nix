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

      # www-data (webapp) needs rw on the synced notes dir. setgid + ACL so
      # files syncthing (root) drops in stay accessible/writable by www-data.
      # /root is 0700 by default — give traverse (x) so www-data reaches Notes.
      systemd.tmpfiles.rules = [
        "d /root 0751 root root - -"
        "d /root/Notes 2775 root www-data - -"
        "A /root/Notes - - - - u:www-data:rwx d:u:www-data:rwx"
      ];
    };
  };
}
