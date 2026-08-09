{
  den.aspects.ssh = {
    # The per-user agenix secrets (github key, oracle key) are declared on the
    # user aspect itself, in modules/user/lunixose.nix, since they are
    # inherently per-user. This aspect only configures the system-wide
    # openssh server and ssh client.
    nixos = {
      services.openssh.enable = true;
      programs.ssh = {
        startAgent = true;
        extraConfig = ''
          Host oraclevps
              HostName 217.142.232.103
              User ubuntu
              IdentityFile ~/.ssh/ssh-key-2026-08-09.key
          Host *
              AddKeysToAgent yes
              IdentityFile ~/.ssh/github

        '';
      };
    };
  };
}
