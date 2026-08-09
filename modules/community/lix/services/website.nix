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
          path = [ pkg ];
          environment = {
            NODE_ENV = "production";
            PORT = "3100";
            NOTES_FILE = "/srv/www/data/notes.txt";
            FINANCE_FILE = "/srv/www/data/finance.json";
          };
          serviceConfig = {
            Type = "exec";
            ExecStart = "${pkg}/share/lunatix-website/.output/server/index.mjs";
            Restart = "on-failure";
            RestartSec = 3;
            DynamicUser = true;
            # data dir writable by the dynamic user
            StateDirectory = [ "www" "www/data" ];
          };
        };
      };
  };
}
