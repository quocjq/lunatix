{
  __findFile,
  ...
}:
{
  den.aspects.lunixose = { user, ... }: {
    # Per-user agenix secrets. `lig.agenix` collects these via the `secrets`
    # quirk and exposes them up to the host scope so each user gets their own
    # decrypted symlinks under their home directory.
    secrets = [
      {
        name = "dns";
        path = "/run/agenix/dns";
        owner = "root";
        group = "root";
        mode = "0400";
      }
      {
        name = "github";
        path = "/home/lunixose/.ssh/github";
        owner = user.userName;
        group = "users";
        mode = "600";
      }
      {
        name = "oraclevps";
        path = "/home/lunixose/.ssh/ssh-key-2026-08-09.key";
        owner = user.userName;
        group = "users";
        mode = "600";
      }
      {
        name = "env";
        path = "/home/lunixose/.config/secrets/env";
        owner = user.userName;
        group = "users";
        mode = "600";
      }
    ];

    includes = [
      <den/define-user>
      <den/primary-user>
      <lix/tools>
      <lix/development>
      <lix/communication>
      <lix/system>
      <lix/gaming>
      <lix/herdr>
    ];
    user = { pkgs, ... }: {
      initialHashedPassword = "$6$.u5xmD5jRI69qFuA$L/M.0dWMo4pS5tLIsgZboyEzZeVXI.v17sG0SDv7WekS.VNEwyEbswld8yV3FHXymhUCnc1phCxyHxpi66uLs.";
      packages = with pkgs; [
        # codecrafters-cli
        opencode
        opencode-desktop
        devenv
        just
        nh
        ghostty
        neovim
        wget
        curl
        obsidian
        onlyoffice-desktopeditors
      ];
    };
    os = {
      home-manager.backupFileExtension = "backup";
    };
  };
}
