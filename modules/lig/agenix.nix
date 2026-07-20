{ inputs, den, ... }:
let
  # Encrypted *.age files and the agenix rules file live next to this module,
  # under modules/lig/_secrets/. The leading `_` makes import-tree skip the
  # directory, so the rules file (secrets.nix) is not evaluated as a flake
  # module. A producer that emits `secrets = [ { name = "github"; ... } ]` is
  # wired to modules/lig/_secrets/github.age automatically.
  secretsDir = ./_secrets;
in
{
  flake-file.inputs.agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };

  # The `secrets` quirk: any aspect can *declare* an agenix secret without
  # knowing about agenix. `lig.agenix` is the single consumer that turns every
  # declaration into an `age.secrets.<name>` entry.
  #
  # Producer contract (emit at aspect top level, list auto-flattens):
  #   secrets = [
  #     { name = "github";                       # -> modules/lig/secrets/github.age
  #       path = "/home/lunixose/.ssh/github";   # symlink target for the decrypted file
  #       owner = "lunixose";                    # optional, default "root"
  #       group = "users";                       # optional, default "root"
  #       mode  = "600"; }                       # optional, default "400"
  #   ];
  den.quirks.secrets = {
    description = "agenix secret declarations collected by lig.agenix";
  };

  # `secrets` may be declared on user aspects (e.g. lix.bash) but is consumed by
  # lig.agenix at the host (nixos) scope. Same-scope aggregation is automatic;
  # this policy exposes user-scope declarations up to their host so they reach
  # the consumer too. Registered in den.default.includes below so it is always on.
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

        # `agenix` CLI (agenix -e <file>.age) for editing secrets.
        environment.systemPackages = [
          inputs.agenix.packages.${pkgs.system}.default
        ];

        # Host identity used to decrypt at activation. These are the defaults,
        # made explicit: the openssh host key must be a recipient in secrets.nix.
        age.identityPaths = [
          "/etc/ssh/ssh_host_ed25519_key"
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
