{
  server.lunatix-deploy = {
    nixos =
      { pkgs, ... }:
      let
        repo = "git@github.com:quocjq/lunatix.git";
        # github SSH key: declared once by server/forgejo-runner.nix (owner
        # gitea-runner); this timer runs as root and reads it directly (root
        # bypasses permission checks).
        githubKey = "/var/lib/gitea-runner/default/.ssh/github";
        revFile = "/var/lib/lunatix-deploy/last-switched-rev";
        # Root-only: watches lunatix main, runs `nixos-rebuild switch` when the
        # branch advances. The runner never runs the switch (it can't kill
        # itself); this timer owns deployment. Local-path flake + explicit rev
        # = no github flake-cache stale-rev problem.
        #
        # flock serializes against a manual `nixos-rebuild switch` (an admin
        # deploy and this timer otherwise collide on systemd's fixed transient
        # unit name nixos-rebuild-switch-to-configuration).
        deployScript = pkgs.writeShellScript "lunatix-deploy" ''
          set -euo pipefail

          exec 9>/var/lib/lunatix-deploy/.switch.lock
          if ! flock -n 9; then
            echo "lunatix: another switch is running (admin deploy?), skipping"
            exit 0
          fi

          # If a manual `nixos-rebuild switch` (admin via ssh) is mid-flight it
          # occupies the fixed transient unit; wait for it rather than collide.
          while systemctl is-active --quiet nixos-rebuild-switch-to-configuration; do
            echo "lunatix: waiting for in-flight admin switch..."
            sleep 10
          done

          export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i ${githubKey} -o StrictHostKeyChecking=accept-new"

          mkdir -p /var/lib/lunatix-deploy

          if [ ! -d /var/lib/lunatix-deploy/lunatix/.git ]; then
            ${pkgs.git}/bin/git clone --no-checkout ${repo} /var/lib/lunatix-deploy/lunatix
          fi
          # Force the remote URL every run: an older deploy script cloned from
          # forgejo, and the checkout's `origin` would otherwise keep pointing
          # there (a stale mirror), silently ignoring the github chain.
          ${pkgs.git}/bin/git -C /var/lib/lunatix-deploy/lunatix remote set-url origin ${repo}
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

