{
  lib,
  den,
  ...
}:
{
  den.default.nixos.system.stateVersion = "26.05";
  # den.default.homeManager.home.stateVersion = "26.05";
  den.default.includes = [
    den.aspects.settings
    den.batteries.hostname
  ];
  # login shell: user-shell battery would force home-manager programs.bash
  # (colliding with nix-maid's .bashrc); set the shell explicitly instead.
  den.default.nixos.programs.bash.enable = true;
  # den.default.homeManager.programs.bash.enable = lib.mkForce false;
  # home-manager + nix-maid in parallel: migrate modules one class at a time.
  # Drop "homeManager" once the HM tail (emacs/nixcord/stylix/
  # plasma/caelestia/zenwser) is gone, drop "maid" to roll back.
  den.schema.user.classes = lib.mkDefault [
    # "homeManager"
    "maid"
  ];

}
