let
  # User public key:
  lunixose = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHkCjExNYxUFFr2joRL8Rq0jE/tEDfNR/hrKReH4FS9l lunixose";

  # Hosts public key:
  igloo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBSOviyXGBA6K0nHcKsZf1a8UXV6etN5ePvUyw6+tYXp root@nixos";

  all = [
    lunixose
    igloo
  ];
in
{
  "github.age".publicKeys = all;
  "oraclevps.age".publicKeys = all;
  "env.age".publicKeys = all;
  "github-token.age".publicKeys = all;
  "dns.age".publicKeys = all;
  "duckdns-token.age".publicKeys = all;
  "pihole-password.age".publicKeys = all;
  "website-admin-password.age".publicKeys = all;

  # Add a line here for every new secret, then declare a matching entry in the
  # `secrets` quirk (see modules/settings/ssh.nix or modules/lunix/bash.nix) so
  # lig.agenix decrypts it.
}
