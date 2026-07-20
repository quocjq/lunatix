# agenix rules file. This is PUBLIC (only public keys live here) and is read by
# the `agenix` CLI to decide who can decrypt each *.age file in this directory.
#
# Run `agenix -e github.age` from THIS directory to create/edit a secret.
#
# Fill in the two public keys below, then map each *.age file to its recipients.
let
  # Your personal SSH public key (so you can edit secrets from your machine):
  #   cat ~/.ssh/id_ed25519.pub
  lunixose = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkCjExNYxUFFr2joRL8Rq0jE/tEDfNR/hrKReH4FS9l lunixose";

  # The igloo host public key (so the machine can decrypt at boot):
  #   cat /etc/ssh/ssh_host_ed25519_key.pub
  igloo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBSOviyXGBA6K0nHcKsZf1a8UXV6etN5ePvUyw6+tYXp root@nixos";

  all = [
    lunixose
    igloo
  ];
in
{
  "github.age".publicKeys = all;
  "oraclevps.age".publicKeys = all;

  # Shell environment exports (API keys, tokens) sourced from bashrc.
  # Declared by the `secrets` quirk in modules/lunix/bash.nix.
  "env.age".publicKeys = all;

  # Add a line here for every new secret, then declare a matching entry in the
  # `secrets` quirk (see modules/settings/ssh.nix or modules/lunix/bash.nix) so
  # lig.agenix decrypts it.
}
