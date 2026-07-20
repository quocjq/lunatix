#!/usr/bin/env -S just --justfile

secrets_dir := "modules/lig/_secrets"
identity := "~/.ssh/ssh_user_lunixose_ed25519"

# List available recipes
default:
    @just --list

# --- Bootstrap: reinstall on a fresh NixOS installer ----------------------
# A fresh installer doesn't have flakes enabled, so these recipes turn the
# experimental features on from the command line. The only tool you need to
# reach them is `just` itself:  nix-shell -p just git

# nix with flakes + nix-command enabled explicitly (for the fresh installer).
nix := "nix --extra-experimental-features 'nix-command flakes'"

# Enter the bootstrap toolbox shell (disko, cryptsetup, nixos-install-tools…).
bootstrap:
    {{nix}} develop

# Partition, format and mount the Latitude 3250 disk at /mnt (DESTRUCTIVE).
# Stash the LUKS passphrase first:  echo -n 'your-passphrase' > /tmp/secret.key
disko-format:
    sudo {{nix}} run github:nix-community/disko -- --mode destroy,format,mount --flake .#igloo

# Install the igloo system onto the mounted /mnt.
install:
    sudo nixos-install --flake .#igloo --no-root-passwd

# Build the igloo host configuration (no activation)
build:
    {{nix}} run .#igloo

# Build and activate the igloo host configuration
switch:
    {{nix}} run .#igloo -- switch

# Test the configuration in a throwaway VM
vm:
    {{nix}} run .#vm

# Regenerate flake.nix after changing inputs declared inside modules
write-flake:
    {{nix}} run .#write-flake

# Update every flake input and refresh flake.lock
update:
    {{nix}} flake update

# Format all Nix files
fmt:
    {{nix}} fmt

# Garbage-collect old generations, keeping at least the 5 most recent
# (and anything newer than 5 days), then hard-link identical store paths.
# `nh clean all` covers profiles + boot entries; the final optimise dedupes.
clean:
    nh clean all --keep 5 --keep-since 5d
    {{nix}} store optimise

# Aggressive variant: keep the 5 newest generations regardless of age.
clean-hard:
    nh clean all --keep 5 --keep-since 0
    {{nix}} store optimise

# Deduplicate the nix store without removing any generations.
optimise:
    {{nix}} store optimise

# Create or edit an encrypted secret, e.g. `just secret github`
secret name:
    cd {{secrets_dir}} && {{nix}} run github:ryantm/agenix -- -e {{name}}.age -i {{identity}}

# Encrypt an existing plaintext file into a secret,
# e.g. `just secret-import github ~/.ssh/github`
secret-import name file:
    cd {{secrets_dir}} && EDITOR="cp {{file}}" {{nix}} run github:ryantm/agenix -- -e {{name}}.age

# Decrypt a secret to stdout (sanity check), e.g. `just secret-show github`
secret-show name:
    cd {{secrets_dir}} && {{nix}} run github:ryantm/agenix -- -d {{name}}.age -i {{identity}}

# Re-encrypt every secret for the current recipients in secrets.nix.
# Run this after adding/removing a key in secrets.nix.
rekey:
    cd {{secrets_dir}} && {{nix}} run github:ryantm/agenix -- --rekey -i {{identity}}

# Replace the GitHub key: generate a fresh keypair, encrypt the private half
# into github.age, and print the new public key to register on GitHub.
# Use this when the old GitHub key expired.
new-github-key:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    ssh-keygen -t ed25519 -f "$tmp/github" -N "" -C "lunixose@github"
    ( cd {{secrets_dir}} && EDITOR="cp $tmp/github" {{nix}} run github:ryantm/agenix -- -e github.age )
    echo
    echo "==> github.age re-encrypted with the new key."
    echo "==> Add this NEW public key at https://github.com/settings/keys and delete the old one:"
    echo
    cat "$tmp/github.pub"
    echo
    echo "Then: git add {{secrets_dir}}/github.age && just switch"
