{ inputs, den, ... }:
let
  secretsDir = ./_secrets;
in
{
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  # The `secrets`: any aspect can *declare* an agenix secret without
  # knowing about agenix. `lig.agenix` is the single consumer that turns every
  # declaration into an `age.secrets.<name>` entry.
  #
  # Producer contract (emit at aspect top level, list auto-flattens):
  #   secrets = [
  #     { name = "github";                       # -> modules/lig/secrets/github.age
  #       path = "/home/${user.userName}/.ssh/github";   # symlink target for the decrypted file
  #       owner = "${user.userName}";                  # optional, default "root"
  #       group = "users";                       # optional, default "root"
  #       mode  = "600"; }                       # optional, default "400"
  #   ];
  den.quirks.secrets = {
    description = "agenix secret declarations collected by lig.agenix";
  };

  den.policies.expose-secrets =
    { ... }:
    let
      inherit (den.lib.policy) pipe;
    in
    [ (pipe.from "secrets" [ pipe.expose ]) ];

  den.default.includes = [ den.policies.expose-secrets ];

  lig.agenix = {
    nixos =
      {
        secrets,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ inputs.agenix.nixosModules.default ];
        environment.systemPackages = [
          inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];

        age.secrets = lib.listToAttrs (
          map (s: {
            inherit (s) name;
            value = {
              file = secretsDir + "/${s.name}.age";
              path = s.path or "/run/agenix/${s.name}";
              owner = s.owner or "root";
              group = s.group or "root";
              mode = s.mode or "400";
            };
          }) secrets
        );
      };
  };
}
