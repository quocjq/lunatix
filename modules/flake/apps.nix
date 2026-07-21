# enables `nix run .#doomacs` and `nix run .#nixcord`, launching these
# programs standalone using the packages already built by the igloo config's
# home-manager, without switching the whole system.
{ inputs, ... }:
{
  perSystem = _: {
    packages =
      let
        hm = inputs.self.nixosConfigurations.igloo.config.home-manager.users.lunixose;
      in
      {
        doomacs = hm.programs.doom-emacs.finalEmacsPackage;
        nixcord = hm.programs.nixcord.finalPackage.discord;
      };
  };
}
