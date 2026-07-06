{
  den.aspects.x11 = {
    nixos = {
      services.xserver.enable = true;
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };
    };
  };

}
