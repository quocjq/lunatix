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

# Bootstrap via devenv — same toolbox, but powered by cachix/devenv.
bootstrap-dev:
    {{nix}} run github:cachix/devenv -- shell

# Enter the daily devenv shell (mirrors `.envrc`'s `use flake .#dev`).
dev:
    {{nix}} run github:cachix/devenv -- shell dev

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

# Create new ssh key and add it to age & provide public key
# Type of key: dsa, ecdsa, ecdsa-sk, ed25519, ed25519-sk, rsa
new-key type name:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    ssh-keygen -t {{type}} -f "$tmp/{{name}}" -N "" -C "lunixose@{{name}}"
    ( cd {{secrets_dir}} && EDITOR="cp $tmp/{{name}}" {{nix}} run github:ryantm/agenix -- -e {{name}}.age )
    echo
    cat "$tmp/{{name}}.pub"
    echo
    echo "Then: git add {{secrets_dir}}/{{name}}.age && just switch"
