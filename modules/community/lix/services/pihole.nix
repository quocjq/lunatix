{
  den.aspects.pihole = {
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

        # Apply the web admin password at boot from the agenix secret. Pi-hole
        # stores a hash in /etc/pihole/pihole.toml; `setpassword` recomputes it
        # from the plaintext each boot.
        systemd.services.pihole-setpassword = {
          description = "Apply Pi-hole web password from agenix secret";
          after = [ "pihole-ftl.service" "pihole-web.service" ];
          wants = [ "pihole-ftl.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [ pkgs.pihole ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "pihole-setpassword" ''
              set -euo pipefail
              if [ -f /run/pihole/password ]; then
                pihole setpassword "$(cat /run/pihole/password)"
              fi
            '';
            RemainAfterExit = true;
          };
        };
      };
  };
}
