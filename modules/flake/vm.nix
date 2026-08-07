# enables `nix run .#vm`. Tests the config in a throwaway VM before a real
# switch, no reboot needed.
{ inputs, den, ... }:
{
  den.aspects.igloo.includes = [ (den.batteries.vm-autologin "lunixose") ];

  perSystem =
    { pkgs, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text =
          let
            host = inputs.self.nixosConfigurations.igloo.config;
          in
          ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
      };
    };
}
