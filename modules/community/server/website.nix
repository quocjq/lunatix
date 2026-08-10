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
        name = "website-admin-password";
        path = "/run/website/admin-password";
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
        systemd.tmpfiles.rules = [
          "d /srv/www 0755 root root - -"
          "d /srv/www/data 0755 www-data www-data - -"
        ];

        systemd.services.lunatix-website = {
          description = "lunatix website (editor)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            NODE_ENV = "production";
            PORT = "3100";
            DOCS_DIR = "/srv/www/data/docs";
            NOTES_DIR = "/root/Notes";
            ADMIN_PASSWORD_FILE = "/run/website/admin-password";
          };
          serviceConfig = {
            Type = "exec";
            ExecStartPre = [
              # `+` runs these as root (ExecStartPre defaults to the service user)
              "+${pkgs.coreutils}/bin/mkdir -p /srv/www/data/docs /root/Notes"
              # self-healing ACLs: www-data needs traverse on /root and rw on Notes
              "+${pkgs.acl}/bin/setfacl -m u:www-data:--x /root"
              "+${pkgs.acl}/bin/setfacl -Rm u:www-data:rwx,d:u:www-data:rwx /root/Notes"
              "+${pkgs.coreutils}/bin/chmod -R 2775 /root/Notes"
              "+${pkgs.coreutils}/bin/chown -R root:www-data /root/Notes"
            ];
            ExecStart = "${pkgs.nodejs}/bin/node ${pkg}/share/lunatix-website/.output/server/index.mjs";
            WorkingDirectory = "${pkg}/share/lunatix-website/.output/server";
            Restart = "on-failure";
            RestartSec = 3;
            User = "www-data";
            Group = "www-data";
          };
        };
      };
  };
}
