{
  den.aspects.settings = {
    homeManager = {
      services.ssh-agent.enable = true;
      programs.ssh = {
        enable = true;
        settings."*" = {
          ForwardAgent = true;
          addKeysToAgent = "yes";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
      };
    };
    nixos = {
      services.openssh.enable = true;
    };
  };
}
