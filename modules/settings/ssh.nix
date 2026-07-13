{
  den.aspects.ssh = {
    nixos = {
      services.openssh.enable = true;
      programs.ssh = {
        startAgent = true;
        extraConfig = ''
          Host oraclevps
            HostName 217.142.232.103
            User ubuntu
            IdentityFile ~/.ssh/ssh-key-2026-05-09.key
          AddKeysToAgent yes
        '';
      };
    };
  };
}
