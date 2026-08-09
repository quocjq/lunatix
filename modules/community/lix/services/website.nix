{
  inputs,
  ...
}:
{
  flake-file.inputs.website = {
    url = "github:quocjq/website";
  };

  den.aspects.website = {
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
          description = "lunatix Nuxt dashboard";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            NODE_ENV = "production";
            PORT = "3100";
            NOTES_FILE = "/srv/www/data/notes.txt";
            FINANCE_FILE = "/srv/www/data/finance.json";
          };
          serviceConfig = {
            Type = "exec";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /srv/www/data";
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
