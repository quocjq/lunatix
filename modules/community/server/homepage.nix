{
  inputs,
  ...
}:
{
  flake-file.inputs.homepage = {
    # tarball input: fetched over https without the `git` binary (oracle has
    # none; git+https inputs require it). Forgejo serves the archive URL.
    url = "https://git.lunixose.duckdns.org/lunixose/homepage/archive/main.tar.gz";
    type = "tarball";
  };

  server.homepage = {
    nixos =
      { pkgs, ... }:
      let
        pkg = inputs.homepage.packages.${pkgs.stdenv.hostPlatform.system}.default;
        configDir = "/root/homepage";
      in
      {
        users.users.www-data = {
          isSystemUser = true;
          group = "www-data";
        };
        users.groups.www-data = { };

        systemd.services.lunatix-homepage = {
          description = "lunatix homepage (astro SSR service dashboard)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            NODE_ENV = "production";
            PORT = "3200";
            HOST = "127.0.0.1";
            HOMEPAGE_CONFIG = "${configDir}/services.yaml";
          };
          serviceConfig = {
            Type = "exec";
            ExecStartPre = [
              # `+` runs these as root (ExecStartPre defaults to the service user)
              "+${pkgs.coreutils}/bin/mkdir -p ${configDir}"
              # self-healing ACLs: www-data needs traverse on /root and rw on the
              # config dir so it can live-read services.yaml (mirrors blog/Notes).
              "+${pkgs.acl}/bin/setfacl -m u:www-data:--x /root"
              "+${pkgs.acl}/bin/setfacl -Rm u:www-data:rx,d:u:www-data:rx ${configDir}"
              "+${pkgs.coreutils}/bin/chmod -R 2755 ${configDir}"
              "+${pkgs.coreutils}/bin/chown -R root:www-data ${configDir}"
            ];
            ExecStart = "${pkgs.nodejs}/bin/node ${pkg}/share/lunatix-homepage/server/entry.mjs";
            Restart = "on-failure";
            RestartSec = 3;
            User = "www-data";
            Group = "www-data";
          };
        };
      };
  };
}
