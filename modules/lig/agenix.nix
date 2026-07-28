{ inputs, den, ... }:
let
  secretsDir = ./_secrets;
in
{
  flake-file.inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        imports = [
          inputs.agenix.nixosModules.default
          # inputs.agenix-rekey.nixosModules.default
        ];
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
        # age.rekey = {
        #   # Obtain this using `ssh-keyscan` or by looking it up in your ~/.ssh/known_hosts
        #   hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkCjExNYxUFFr2joRL8Rq0jE/tEDfNR/hrKReH4FS9l lunixose";
        #   # The path to the master identity used for decryption. See the option's description for more information.
        #   masterIdentities = [ "/home/lunixose/.ssh/ssh_user_lunixose_ed25519.pub" ];
        #   #masterIdentities = [ "/home/myuser/master-key" ]; # External master key
        #   #masterIdentities = [
        #   #  # It is possible to specify an identity using the following alternate syntax,
        #   #  # this can be used to avoid unecessary prompts during encryption.
        #   #  {
        #   #    identity = "/home/myuser/master-key.age"; # Password protected external master key
        #   #    pubkey = "age1qyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqs3290gq"; # Specify the public key explicitly
        #   #  }
        #   #];
        #   storageMode = "local";
        #   # Choose a directory to store the rekeyed secrets for this host.
        #   # This cannot be shared with other hosts. Please refer to this path
        #   # from your flake's root directory and not by a direct path literal like ./secrets
        #   localStorageDir = ./. + "/_secrets";
        # };

      };
  };
}
