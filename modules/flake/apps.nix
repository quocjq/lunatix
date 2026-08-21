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
        # `nix run .#facter -- -o modules/community/lix/hardware/facter.json`
        # regenerates the hardware report consumed by the igloo host aspect.
        facter = pkgs.nixos-facter;
        # Deploy/reinstall (--build-on remote) and installs over
        # SSH. nixos-anywhere auto-downloads the aarch64 kexec image.
        #   nix run .#deploy -- root@<ip>
        deploy = inputs.nixos-anywhere.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
  };
}
