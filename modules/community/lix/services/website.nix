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
            ExecStart = "${pkgs.nodejs}/bin/node ${pkg}/share/lunatix-website/.output/server/index.mjs";
            WorkingDirectory = "${pkg}/share/lunatix-website/.output/server";
            Restart = "on-failure";
            RestartSec = 3;
            DynamicUser = true;
            StateDirectory = [ "www/data" ];
          };
        };
      };
  };
}
