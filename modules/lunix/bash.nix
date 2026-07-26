{
  lix.bash = {
    # The agenix secret holding shell environment exports is declared on the
    # user aspect itself, in modules/user/lunixose.nix, since it is
    # inherently per-user. This aspect only configures the bash program and
    # sources the decrypted secret from the standard location.
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
