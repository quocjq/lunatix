{
  lix.nushell = {
    homeManager = {
      programs.nushell = {
        enable = true;

        # Same per-user agenix env as modules/lunix/bash.nix. The file is
        # dropped at ~/.config/secrets/env by the agenix secret declared on
        # the user aspect (modules/user/lunixose.nix). Skip silently when
        # the file is absent so a fresh machine still starts a usable shell.
        extraConfig = ''
          const env_file = $"($nu.home-path)/.config/secrets/env"
          if ($env_file | path exists) {
            source $env_file
          }
        '';
      };
    };
  };
}
