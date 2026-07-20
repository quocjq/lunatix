{
  lib,
  den,
  ...
}:
{
  den.default.nixos.system.stateVersion = "26.05";
  den.default.homeManager.home.stateVersion = "26.05";
  den.default.includes = [
    den.aspects.settings
    den.batteries.os-user
    den.batteries.inputs'
    (den.batteries.user-shell "bash")
  ];
  # enable hm by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

}
