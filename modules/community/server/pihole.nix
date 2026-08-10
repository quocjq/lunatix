{
  server.pihole = {
    secrets = [
      {
        name = "pihole-password";
        path = "/run/pihole/password";
        owner = "root";
        group = "root";
        mode = "0400";
      }
    ];

    nixos =
      { pkgs, ... }:
      {
        services.pihole-ftl = {
          enable = true;
          openFirewallDNS = true;
          settings = {
            webserver = {
              api = {
                # ephemeral CLI password so `pihole` can talk to FTL's socket
                cli_pw = true;
              };
            };
            dns = {
              "domain-needed" = true;
              "bogus-priv" = true;
            };
          };
        };
        services.pihole-web = {
          enable = true;
          hostName = "127.0.0.1";
          ports = [ 8080 ];
        };

        # Allow FTL to accept the web password at runtime (module defaults
        # misc.readOnly = true, which rejects `--config` writes).
        services.pihole-ftl.settings.misc.readOnly = pkgs.lib.mkForce false;

        # Apply the web admin password at boot from the agenix secret. Uses the
        # FTL binary directly (`pihole` re-execs via sudo and fails to write).
        systemd.services.pihole-setpassword = {
          description = "Apply Pi-hole web password from agenix secret";
          after = [ "pihole-ftl.service" "pihole-web.service" ];
          wants = [ "pihole-ftl.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "pihole-setpassword" ''
              set -euo pipefail
              if [ -f /run/pihole/password ]; then
                ${pkgs.pihole-ftl}/bin/pihole-FTL --config webserver.api.password "$(cat /run/pihole/password)"
              fi
            '';
            RemainAfterExit = true;
          };
        };
      };
  };
}
