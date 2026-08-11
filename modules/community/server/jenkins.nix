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
      { pkgs, ... }:
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
          port = 8080;
          # CI is internal-only: no caddy vhost, reach it via
          #   ssh -L 8080:127.0.0.1:8080 oraclevps
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
      };
  };
}
