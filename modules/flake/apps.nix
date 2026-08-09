# enables `nix run .#emacs` and `nix run .#nixcord`, launching these
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
        emacs = hm.services.emacs.package;
        doomacs = hm.services.emacs.package; # compat alias, drop later
        nixcord = hm.programs.nixcord.finalPackage.discord;
        # `nix run .#facter -- -o modules/community/lix/hardware/latitude3250.json`
        # regenerates the hardware report consumed by the igloo host aspect.
        facter = pkgs.nixos-facter;
        # Deploy/reinstall the oracle host from its current Ubuntu: builds the
        # aarch64 closure on the target (--build-on remote) and installs over
        # SSH. nixos-anywhere auto-downloads the aarch64 kexec image.
        #   nix run .#deploy-oracle -- root@<ip>
        deploy-oracle = inputs.nixos-anywhere.packages.${pkgs.system}.default;
      };
  };
}
