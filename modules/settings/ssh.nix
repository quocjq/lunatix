{ user, ... }:
{
  den.aspects.ssh = {
    # Declare the private keys as agenix secrets. These flow through the
    # `secrets` quirk to `lig.agenix`, which decrypts each *.age file to the
    # given `path` at activation (a symlink into the nix-store-backed secret).
    # The encrypted files live in modules/lig/secrets/<name>.age.
    secrets = [
      {
        name = "github";
        path = "/home/${user.userName}/.ssh/github";
        owner = user.userName;
        group = "users";
        mode = "600";
      }
      {
        name = "oraclevps";
        path = "/home/${user.userName}/.ssh/ssh-key-2026-05-09.key";
        owner = user.userName;
        group = "users";
        mode = "600";
      }
    ];

    nixos = {
      services.openssh.enable = true;
      programs.ssh = {
        startAgent = true;
        extraConfig = ''
          Host oraclevps
              HostName 217.142.232.103
              User ubuntu
              IdentityFile ~/.ssh/ssh-key-2026-05-09.key
          Host *
              AddKeysToAgent yes
              IdentityFile ~/.ssh/github

        '';
      };
    };
  };
}
