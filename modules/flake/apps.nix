# enables `nix run .#doomacs` and `nix run .#nixcord`, launching these
# programs standalone using the packages already built by the igloo config's
# home-manager, without switching the whole system.
{ inputs, ... }:
{
  perSystem = _: {
    packages =
      let
        hm = inputs.self.nixosConfigurations.igloo.config.home-manager.users.lunixose;
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      in
      {
        doomacs = hm.programs.doom-emacs.finalEmacsPackage;
        nixcord = hm.programs.nixcord.finalPackage.discord;
        # `nix run .#facter -- -o modules/hardware/latitude3250.json` regenerates
        # the hardware report consumed by modules/hardware/latitude3250.nix.
        facter = pkgs.nixos-facter;
      };
  };
}
