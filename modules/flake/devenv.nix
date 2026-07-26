# Bootstrap devenv shell — parallel to modules/flake/devshell.nix but
# built on cachix/devenv instead of `nix develop` / `mkShellNoCC`. The
# `just bootstrap-dev` recipe below enters this shell.
{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];

  perSystem =
    { pkgs, system, ... }:
    {
      devenv.shells = {
        # `just bootstrap-dev` lands here on a fresh installer.
        default = {
          packages = with pkgs; [
            just
            git
            cryptsetup
            btrfs-progs
            dosfstools
            gptfdisk
            parted
            util-linux
            nixos-install-tools
            age
            openssh

            # Pinned flake inputs so the tools match flake.lock instead
            # of the installer's channel.
            inputs.disko.packages.${system}.disko
            inputs.disko.packages.${system}.disko-install
            inputs.agenix.packages.${system}.default
          ];

          enterShell = ''
            cat <<'EOF'
            ┌─ lunatix bootstrap devenv shell ─────────────────────────────────┐
            │ Tools: disko, disko-install, cryptsetup, btrfs-progs, gptfdisk,   │
            │        nixos-install-tools, agenix, git, just                     │
            └───────────────────────────────────────────────────────────────────┘

            Same runbook as `just bootstrap` (devshell variant):

              1. Confirm the target disk:
                   lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL
              2. Stash the format-time LUKS passphrase:
                   echo -n 'your-passphrase' > /tmp/secret.key
              3. Format + mount (DESTRUCTIVE):
                   just disko-format
              4. Install:
                   just install
              5. Reboot, then:
                   just switch
            EOF
          '';
        };

        # `direnv` auto-enters this when the developer enters the repo.
        # `.envrc` already references `use flake .#dev --impure`.
        dev = {
          packages = with pkgs; [
            just
            git
            nh
            age
            openssh
          ];
        };
      };
    };
}
