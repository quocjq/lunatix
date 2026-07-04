{
  den.aspects.settings = {
    nixos = {
      services.openssh.enable = true;
      programs.ssh.startAgent = true;
    };
  };
}
