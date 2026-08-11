{
  server.jenkins = {
    secrets = [
      {
        name = "forgejo-token";
        owner = "jenkins";
        group = "jenkins";
        mode = "0400";
      }
    ];

    nixos =
      { pkgs, lib, ... }:
      let
        groovyImport = ./jenkins-groovy/import-token.groovy;
      in
      {
        # jenkins runs `nix build` in its jobs — allow it through the daemon.
        nix.settings.allowed-users = [ "jenkins" ];

        # The groovy import script is only present on the activation path, so
        # seed it into JENKINS_HOME every switch (cp is idempotent). It turns
        # /run/agenix/forgejo-token into a Jenkins credential at startup.
        system.activationScripts.jenkins-init-groovy =
          pkgs.lib.strings.optionalString true ''
            mkdir -p /var/lib/jenkins/init.groovy.d
            cp ${groovyImport} /var/lib/jenkins/init.groovy.d/import-token.groovy
            chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
            chmod 600 /var/lib/jenkins/init.groovy.d/import-token.groovy
          '';

        services.jenkins = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 8081;
          # CI is internal-only: no caddy vhost, reach it via
          #   ssh -L 8081:127.0.0.1:8081 oraclevps
          # (8080 is pihole-FTL's web interface; keep clear of it)
          extraJavaOptions = [
            "-Xms256m"
            "-Xmx1g"
          ];
          # The jobs need these on PATH: git (clone), nix (build the flake
          # derivations), nodejs (npm ci + typecheck/build).
          packages = [
            pkgs.git
            pkgs.nix
            pkgs.nodejs
          ];
          # Plugins installed via the Jenkins UI for now (matches the
          # "create jobs via UI" decision). `plugins = null` keeps any
          # manually-installed .jpi files instead of wiping them.
          #   pipeline (workflow-aggregator), git, credentials, plain-credentials
          plugins = null;
        };

        # The default NixOS hardening (PrivateUsers+PrivateMounts+
        # RestrictNamespaces) blocks Jenkins' durable-task launcher: it unshares
        # into a new mount/user namespace to spawn the job's `sh`, which
        # RestrictNamespaces forbids -> "process apparently never started",
        # exit code -2. Relax only the namespace restrictions; keep the rest.
        systemd.services.jenkins.serviceConfig = {
          RestrictNamespaces = lib.mkForce false;
          PrivateUsers = lib.mkForce false;
          PrivateMounts = lib.mkForce false;
          MountAPIVFS = lib.mkForce false;
          NoNewPrivileges = lib.mkForce false;
        };
      };
  };
}
