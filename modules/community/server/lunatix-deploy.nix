{
  server.lunatix-deploy = {
    secrets = [
      {
        # github SSH deploy key (same secret as igloo's ~/.ssh/github) so the
        # root timer can fetch lunatix from github (the real origin; forgejo is
        # a mirror). The runner pushes to github; this timer watches github.
        name = "github";
        path = "/root/.ssh/github";
        owner = "root";
        group = "root";
        mode = "0600";
      }
    ];

    nixos =
      { pkgs, ... }:
      let
        repo = "git@github.com:quocjq/lunatix.git";
        revFile = "/var/lib/lunatix-deploy/last-switched-rev";
        # Root-only: watches lunatix main, runs `nixos-rebuild switch` when the
        # branch advances. The runner never runs the switch (it can't kill
        # itself); this timer owns deployment. Local-path flake + explicit rev
        # = no github flake-cache stale-rev problem.
        deployScript = pkgs.writeShellScript "lunatix-deploy" ''
          set -euo pipefail

          export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i /root/.ssh/github -o StrictHostKeyChecking=accept-new"

          mkdir -p /var/lib/lunatix-deploy

          if [ ! -d /var/lib/lunatix-deploy/lunatix/.git ]; then
            ${pkgs.git}/bin/git clone --no-checkout ${repo} /var/lib/lunatix-deploy/lunatix
          fi
          ${pkgs.git}/bin/git -C /var/lib/lunatix-deploy/lunatix fetch origin main || true

          new_rev=$(${pkgs.git}/bin/git -C /var/lib/lunatix-deploy/lunatix rev-parse origin/main)
          old_rev="$(cat ${revFile} 2>/dev/null || echo none)"

          if [ "$new_rev" = "$old_rev" ]; then
            echo "lunatix: no new revision ($new_rev), skipping"
            exit 0
          fi

          echo "lunatix: switching $old_rev -> $new_rev"
          ${pkgs.git}/bin/git -C /var/lib/lunatix-deploy/lunatix checkout --detach origin/main

          /run/current-system/sw/bin/nixos-rebuild switch \
            --flake /var/lib/lunatix-deploy/lunatix#oracle

          echo "$new_rev" > ${revFile}
          echo "lunatix: switched and recorded $new_rev"
        '';
      in
      {
        systemd.timers.lunatix-deploy = {
          description = "Watch lunatix main and deploy oracle";
          timerConfig = {
            OnBootSec = "3min";
            OnUnitInactiveSec = "5min";
            Persistent = true;
          };
          wantedBy = [ "timers.target" ];
        };

        systemd.services.lunatix-deploy = {
          description = "Deploy lunatix main to oracle (nixos-rebuild switch)";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = deployScript;
            User = "root";
            PrivateTmp = true;
          };
        };
      };
  };
}

