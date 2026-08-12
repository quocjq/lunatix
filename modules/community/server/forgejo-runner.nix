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
        # github SSH deploy key for the RUNNER (owner gitea-runner, mode 600 —
        # ssh rejects group-readable keys). The deploy timer gets its own copy
        # (server/lunatix-deploy.nix) because ssh also rejects 0640.
        name = "github-runner";
        path = "/var/lib/gitea-runner/default/.ssh/github";
        owner = "gitea-runner";
        group = "gitea-runner";
        mode = "0600";
      }
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        # The runner's jobs call `nix build` — allow it through the daemon.
        nix.settings.allowed-users = [ "gitea-runner" ];

        # gitea-runner must be a REAL user (not DynamicUser): DynamicUser's
        # ephemeral UID changes every service restart, so the StateDirectory
        # (npm cache, act workspaces) gets chowned to a stale UID -> EACCES on
        # npm/esbuild in later runs. Fixed UID keeps file ownership stable.
        users.users.gitea-runner = {
          isSystemUser = true;
          group = "gitea-runner";
          uid = 63182;
        };
        users.groups.gitea-runner = {
          gid = 63182;
        };

        # With DynamicUser disabled, grant the keys group (which owns the
        # shared github ssh key) via SupplementaryGroups.
        systemd.services.gitea-runner-default.serviceConfig = {
          DynamicUser = lib.mkForce false;
        };

        # Pre-create the runner StateDirectory layout so the agenix secrets
        # (mounted at activation, before the service starts) land in a dir
        # owned by gitea-runner, not root.
        systemd.tmpfiles.rules = [
          "d /var/lib/gitea-runner 0750 gitea-runner gitea-runner -"
          "d /var/lib/gitea-runner/default 0750 gitea-runner gitea-runner -"
          "d /var/lib/gitea-runner/default/.cache 0750 gitea-runner gitea-runner -"
          "d /var/lib/gitea-runner/default/.ssh 0700 gitea-runner gitea-runner -"
        ];

        # The runner uses a DynamicUser with an ephemeral $HOME; git+ssh would
        # stall on the github host-key prompt. Point ssh at the agenix-mounted
        # Pre-create the runner StateDirectory so files survive with stable
        # gitea-runner ownership (the workflows set GIT_SSH_COMMAND directly).
        system.activationScripts.runner-ssh-env = ''
          mkdir -p /var/lib/gitea-runner/default
          chown gitea-runner:gitea-runner /var/lib/gitea-runner /var/lib/gitea-runner/default
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
