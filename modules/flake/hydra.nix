# Hydra CI entrypoint: declares the flake `hydraJobs` output — what Hydra's
# flake jobsets evaluate. Only aarch64 jobs build (on oracle, natively);
# x86_64 (igloo) is out of scope unless igloo is later a remote build machine.
{ inputs, lib, config, ... }:
{
  flake.hydraJobs = lib.genAttrs [ "aarch64-linux" ] (system: {
    # Building the oracle NixOS system is the headline CI job.
    oracle = inputs.self.nixosConfigurations.oracle.config.system.build.toplevel;
    # flake-file's check (flake.nix is generated — ensure it's in sync).
    check-flake-file = inputs.self.checks.${system}.check-flake-file;
  });
}
