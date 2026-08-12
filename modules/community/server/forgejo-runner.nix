{
  server.forgejo-runner = {
    secrets = [
      {
        name = "forgejo-runner-token";
        path = "/run/agenix/forgejo-runner-token";
        owner = "gitea-runner";
        group = "gitea-runner";
        mode = "0400";
      }
      {
        # github SSH deploy key (same secret as igloo's ~/.ssh/github) — gives
        # the runner push access to github.com/quocjq/lunatix. The runner runs
        # as a DynamicUser, so the key lives at a stable path under StateDirectory.
        name = "github";
        path = "/var/lib/gitea-runner/default/.ssh/github";
        owner = "root";
        group = "keys";
        mode = "0640";
      }
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        # The runner's jobs call `nix build` — allow it through the daemon.
        nix.settings.allowed-users = [ "gitea-runner" ];

        # gitea-runner is a DynamicUser (not in users.users), so grant the keys
        # group (which owns the shared github ssh key) via SupplementaryGroups.
        systemd.services.gitea-runner-default.serviceConfig.SupplementaryGroups =
          lib.mkForce [ "keys" ];

        # Pre-create the runner StateDirectory layout so the agenix secrets
        # (mounted at activation, before the service starts) land in a dir
        # owned by gitea-runner, not root.
        systemd.tmpfiles.rules = [
          "d /var/lib/gitea-runner 0750 gitea-runner gitea-runner -"
          "d /var/lib/gitea-runner/default 0750 gitea-runner gitea-runner -"
          "d /var/lib/gitea-runner/default/.ssh 0700 gitea-runner gitea-runner -"
        ];

        # The runner uses a DynamicUser with an ephemeral $HOME; git+ssh would
        # stall on the github host-key prompt. Point ssh at the agenix-mounted
        # key and auto-accept the host key for all runner subprocesses.
        system.activationScripts.runner-ssh-env = ''
          cat > /var/lib/gitea-runner/default/.ssh-env <<EOF
          GIT_SSH_COMMAND=ssh -i /var/lib/gitea-runner/default/.ssh/github -o StrictHostKeyChecking=accept-new
          EOF
          chown gitea-runner:gitea-runner /var/lib/gitea-runner/default/.ssh-env
          chmod 600 /var/lib/gitea-runner/default/.ssh-env
        '';

        services.gitea-actions-runner = {
          package = pkgs.forgejo-runner;
          instances.default = {
            enable = true;
            name = "default";
            url = "http://127.0.0.1:3000";
            tokenFile = "/run/agenix/forgejo-runner-token";
            # Native execution on the oracle host — no docker/podman involved.
            labels = [ "host:host" ];
            hostPackages = with pkgs; [
              bash
              coreutils
              curl
              gawk
              gitMinimal
              gnused
              nodejs
              nix
              wget
              openssh
            ];
            settings = {
              runner = {
                # Serialize jobs: a single build can't starve the services, and
                # two jobs bumping the same flake.lock would race.
                capacity = 1;
              };
            };
          };
        };
      };
  };
}
