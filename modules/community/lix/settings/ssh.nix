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
              HostName 217.142.240.255
              User root
              IdentityFile ~/.ssh/ssh_user_lunixose_ed25519
          Host *
              AddKeysToAgent yes
              IdentityFile ~/.ssh/github

        '';
      };
    };
  };
}
