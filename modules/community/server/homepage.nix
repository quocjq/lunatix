{
  inputs,
  ...
}:
{
  flake-file.inputs.homepage = {
    # git input (needs the `git` binary on the build host — oracle gets it
    # via environment.systemPackages below). Updating is `nix flake update
    # homepage` instead of hand-editing a tarball narHash.
    # TEMP: tarball while git boots — flip to git+https below after deploy 1.
    url = "https://git.lunixose.duckdns.org/lunixose/homepage/archive/main.tar.gz";
    type = "tarball";
  };

  server.homepage = {
    nixos =
      { pkgs, ... }:
      let
        pkg = inputs.homepage.packages.${pkgs.stdenv.hostPlatform.system}.default;
      in
      {
        # `git` binary so nix can fetch the git+https input at build time.
        environment.systemPackages = [ pkgs.git ];

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
          };
          serviceConfig = {
            Type = "exec";
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
