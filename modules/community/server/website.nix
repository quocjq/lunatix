{
  inputs,
  ...
}:
{
  flake-file.inputs.website = {
    url = "github:quocjq/website";
  };

  server.website = {
    secrets = [
      {
        name = "syncthing-apikey";
        path = "/run/website/syncthing-apikey";
        owner = "www-data";
        group = "www-data";
        mode = "0400";
      }
    ];

    nixos =
      { pkgs, ... }:
      let
        pkg = inputs.website.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      {
        users.users.www-data = {
          isSystemUser = true;
          group = "www-data";
        };
        users.groups.www-data = { };

        systemd.services.lunatix-website = {
          description = "lunatix website (dashboard + blog)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            NODE_ENV = "production";
            PORT = "3100";
            NOTES_DIR = "/root/Notes";
            SYNCTHING_API_KEY_FILE = "/run/website/syncthing-apikey";
          };
          serviceConfig = {
            Type = "exec";
            ExecStartPre = [
              # `+` runs these as root (ExecStartPre defaults to the service user)
              "+${pkgs.coreutils}/bin/mkdir -p /root/Notes"
              # self-healing ACLs: www-data needs traverse on /root and rw on Notes
              "+${pkgs.acl}/bin/setfacl -m u:www-data:--x /root"
              "+${pkgs.acl}/bin/setfacl -Rm u:www-data:rwx,d:u:www-data:rwx /root/Notes"
              "+${pkgs.coreutils}/bin/chmod -R 2775 /root/Notes"
              "+${pkgs.coreutils}/bin/chown -R root:www-data /root/Notes"
            ];
            ExecStart = "${pkgs.nodejs}/bin/node ${pkg}/share/lunatix-website/index.mjs";
            Restart = "on-failure";
            RestartSec = 3;
            User = "www-data";
            Group = "www-data";
          };
        };
      };
  };
}
