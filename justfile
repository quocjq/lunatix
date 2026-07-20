#!/usr/bin/env -S just --justfile

secrets_dir := "modules/lig/_secrets"
identity := "~/.ssh/ssh_user_lunixose_ed25519"

# List available recipes
default:
    @just --list

# Build the igloo host configuration (no activation)
build:
    nix run .#igloo

# Build and activate the igloo host configuration
switch:
    nix run .#igloo -- switch

# Test the configuration in a throwaway VM
vm:
    nix run .#vm

# Regenerate flake.nix after changing inputs declared inside modules
write-flake:
    nix run .#write-flake

# Update every flake input and refresh flake.lock
update:
    nix flake update

# Format all Nix files
fmt:
    nix fmt

# Create or edit an encrypted secret, e.g. `just secret github`
secret name:
    cd {{secrets_dir}} && nix run github:ryantm/agenix -- -e {{name}}.age -i {{identity}}

# Encrypt an existing plaintext file into a secret,
# e.g. `just secret-import github ~/.ssh/github`
secret-import name file:
    cd {{secrets_dir}} && EDITOR="cp {{file}}" nix run github:ryantm/agenix -- -e {{name}}.age

# Decrypt a secret to stdout (sanity check), e.g. `just secret-show github`
secret-show name:
    cd {{secrets_dir}} && nix run github:ryantm/agenix -- -d {{name}}.age -i {{identity}}

# Re-encrypt every secret for the current recipients in secrets.nix.
# Run this after adding/removing a key in secrets.nix.
rekey:
    cd {{secrets_dir}} && nix run github:ryantm/agenix -- --rekey -i {{identity}}

# Replace the GitHub key: generate a fresh keypair, encrypt the private half
# into github.age, and print the new public key to register on GitHub.
# Use this when the old GitHub key expired.
new-github-key:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    ssh-keygen -t ed25519 -f "$tmp/github" -N "" -C "lunixose@github"
    ( cd {{secrets_dir}} && EDITOR="cp $tmp/github" nix run github:ryantm/agenix -- -e github.age )
    echo
    echo "==> github.age re-encrypted with the new key."
    echo "==> Add this NEW public key at https://github.com/settings/keys and delete the old one:"
    echo
    cat "$tmp/github.pub"
    echo
    echo "Then: git add {{secrets_dir}}/github.age && just switch"
