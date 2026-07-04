{
  den.aspects.settings = {
    nixos = {
      services.xserver.enable = true;
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

}
