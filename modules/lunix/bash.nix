{ ... }:
{
  lix.bash = {
    # Declare an agenix secret holding shell environment exports — API keys,
    # tokens, and anything else too sensitive to commit in the clear. It flows
    # through the `secrets` quirk to `lig.agenix`, which decrypts
    # modules/lig/_secrets/env.age at activation to the path below (owned by
    # lunixose so the interactive shell can read it).
    secrets = [
      {
        name = "env";
        path = "/home/lunixose/.config/secrets/env";
        owner = "lunixose";
        group = "users";
        mode = "600";
      }
    ];

    homeManager = {
      programs.bash = {
        enable = true;
        # Source the decrypted secret env file if agenix has written it. Guarded
        # on readability so a shell still starts on a fresh machine where the
        # secret has not been provisioned yet. `set -a` exports every variable
        # the file defines without needing `export` on each line.
        initExtra = ''
          if [ -r "$HOME/.config/secrets/env" ]; then
            set -a
            . "$HOME/.config/secrets/env"
            set +a
          fi
        '';
      };
    };
  };
}
