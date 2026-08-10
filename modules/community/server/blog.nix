{
  inputs,
  ...
}:
{
  flake-file.inputs.blog = {
    # tarball input: fetched over https without the `git` binary (oracle has
    # none; git+https inputs require it). Forgejo serves the archive URL.
    url = "https://git.lunixose.duckdns.org/lunixose/blog/archive/main.tar.gz";
    type = "tarball";
  };

  server.blog = {
    nixos =
      { pkgs, ... }:
      let
        pkg = inputs.blog.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      {
        users.users.www-data = {
          isSystemUser = true;
          group = "www-data";
        };
        users.groups.www-data = { };

        systemd.services.lunatix-blog = {
          description = "lunatix blog (astro SSR)";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            NODE_ENV = "production";
            PORT = "3100";
            NOTES_DIR = "/root/Notes";
          };
          serviceConfig = {
            Type = "exec";
            ExecStartPre = [
              # `+` runs these as root (ExecStartPre defaults to the service user)
              "+${pkgs.coreutils}/bin/mkdir -p /root/Notes"
              # self-healing ACLs: www-data needs traverse on /root and rw on Notes
              "+${pkgs.acl}/bin/setfacl -m u:www-data:--x /root"
              "+${pkgs.acl}/bin/setfacl -Rm u:www-data:rx,d:u:www-data:rx /root/Notes"
              "+${pkgs.coreutils}/bin/chmod -R 2775 /root/Notes"
              "+${pkgs.coreutils}/bin/chown -R root:www-data /root/Notes"
            ];
            ExecStart = "${pkgs.nodejs}/bin/node ${pkg}/share/lunatix-blog/server/entry.mjs";
            Restart = "on-failure";
            RestartSec = 3;
            User = "www-data";
            Group = "www-data";
          };
        };
      };
  };
}
