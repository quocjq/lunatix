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

nix := "nix --extra-experimental-features 'nix-command flakes' --max-jobs 2"
agenix_cmd := if `bash -c 'command -v agenix 2>/dev/null || true'` != "" { "agenix" } else { nix + " run github:ryantm/agenix --" }
devenv_cmd := if `bash -c 'command -v devenv 2>/dev/null || true'` != "" { "devenv" } else { nix + " run github:cachix/devenv --" }

# Enter the bootstrap toolbox shell (disko, cryptsetup, nixos-install-tools…).
bootstrap:
    {{nix}} develop

# Bootstrap via devenv — same toolbox, but powered by cachix/devenv.
bootstrap-dev:
    {{devenv_cmd}} shell

# Enter the daily devenv shell (mirrors `.envrc`'s `use flake .#dev`).
dev:
    {{devenv_cmd}} shell dev

# Partition, format and mount the Latitude 3250 disk at /mnt (DESTRUCTIVE).
# Stash the LUKS passphrase first:  echo -n 'your-passphrase' > /tmp/secret.key
disko-format:
    sudo {{nix}} run github:nix-community/disko -- --mode destroy,format,mount --flake .#igloo

# Install the igloo system onto the mounted /mnt.
nixos-install:
    sudo nixos-install --flake .#igloo --no-root-passwd

# Basically disko + nixos-install
disko-install host disk:
    sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake .#{{host}} --disk {{disk}}

# Build the igloo host configuration (no activation)
build:
    {{nix}} run .#igloo

# Build and activate the igloo host configuration
switch:
    {{nix}} run .#igloo -- switch

# Switch the ORACLE host remotely (root@oracle, ed25519 key). Run from igloo.
# Do NOT run `just switch` on the oracle box — that builds igloo (x86_64).
switch-oracle:
    ssh oraclevps nixos-rebuild switch --flake github:quocjq/lunatix#oracle

# Deploy the oracle host (currently Ubuntu) — nixos-anywhere + kexec, builds on remote.
# Oracle instances log in as `ubuntu` (passwordless sudo), not root.
# First deploy: --copy-host-keys preserves Ubuntu's host key so agenix secrets
# (rekeyed to that key) decrypt on first boot.
# Usage: just deploy-oracle [ubuntu@ip]
deploy-oracle target:
    {{nix}} run .#deploy-oracle -- --build-on remote --copy-host-keys -i ~/.ssh/ssh-key-2026-08-09.key --flake .#oracle {{target}}

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
    cd {{secrets_dir}} && {{agenix_cmd}} -e {{name}}.age -i {{identity}}

# Encrypt an existing plaintext file into a secret,
# e.g. `just secret-import github ~/.ssh/github`
secret-import name file:
    cd {{secrets_dir}} && EDITOR="cp {{file}}" {{agenix_cmd}} -e {{name}}.age

# Decrypt a secret to stdout (sanity check), e.g. `just secret-show github`
secret-show name:
    cd {{secrets_dir}} && {{agenix_cmd}} -d {{name}}.age -i {{identity}}

# Re-encrypt every secret for the current recipients in secrets.nix.
# Run this after adding/removing a key in secrets.nix.
rekey:
    cd {{secrets_dir}} && {{agenix_cmd}} --rekey -i {{identity}}

# Create new ssh key and add it to age & provide public key
# Type of key: dsa, ecdsa, ecdsa-sk, ed25519, ed25519-sk, rsa
new-ssh-key type name:
    #!/usr/bin/env bash
    set -euo pipefail
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    ssh-keygen -t {{type}} -f "$tmp/{{name}}" -N "" -C "lunixose@{{name}}"
    ( cd {{secrets_dir}} && EDITOR="cp $tmp/{{name}}" {{agenix_cmd}} -e {{name}}.age )
    echo
    cat "$tmp/{{name}}.pub"
    echo
    echo "Then: git add {{secrets_dir}}/{{name}}.age && just switch"
