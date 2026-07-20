# Bootstrap devshell — the toolbox you drop into on a fresh NixOS installer
# after git cloning this repo. `nix develop` here gives you every CLI the
# reinstall needs (disko, the partition/luks/fs tools it shells out to, the
# nixos-install family, agenix for secrets, plus git/just) without polluting
# the installed system's package set.
#
#   Fresh boot -> nix-shell -p git -> git clone <repo> -> cd lunatix
#   nix develop            # you are now here
#
# The runbook printed by shellHook mirrors modules/disko/latitude3250.nix:
# disko formats with `disko.enableConfig = false`, so it only partitions/
# formats — the running system's mounts stay hand-written in the host module.
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          # Task runner + fetch — `just` mirrors the recipes in ./justfile,
          # git is how you got here (and how you re-pull after edits on tty).
          pkgs.just
          pkgs.git

          # disko itself: `disko --mode destroy,format,mount <flake>#igloo` or
          # the one-shot `disko-install`. Pulled from the pinned input so it
          # matches flake.lock rather than the installer's channel.
          inputs.disko.packages.${system}.disko
          inputs.disko.packages.${system}.disko-install

          # Tools disko shells out to while formatting the Latitude layout.
          # Present on the graphical ISO but not the minimal one, so pin them.
          pkgs.cryptsetup # LUKS2 containers (root + swap)
          pkgs.btrfs-progs # btrfs + subvolumes (home, nix)
          pkgs.dosfstools # mkfs.vfat for the ESP
          pkgs.gptfdisk # sgdisk / GPT labels (EFI, root)
          pkgs.parted
          pkgs.util-linux # wipefs, lsblk, blkid — inspect before you destroy

          # Install the closure onto the freshly mounted /mnt.
          pkgs.nixos-install-tools # nixos-install, nixos-generate-config, nixos-enter

          # Secrets: the host decrypts *.age with its ssh host key, so the new
          # box must be a recipient in _secrets/secrets.nix before first switch.
          inputs.agenix.packages.${system}.default
          pkgs.age
          pkgs.openssh # ssh-keygen for a fresh host key / recipient pubkey
        ];

        shellHook = ''
          cat <<'EOF'
          ┌─ lunatix bootstrap shell ─────────────────────────────────────────┐
          │ Tools: disko, disko-install, cryptsetup, btrfs-progs, gptfdisk,   │
          │        nixos-install-tools, agenix, git, just                     │
          └───────────────────────────────────────────────────────────────────┘

          Reinstall on a fresh disk (Latitude 3250 layout) — driven by `just`:

            1. Confirm the target disk still matches modules/disko/latitude3250.nix
               (device = /dev/disk/by-id/nvme-eui...). Inspect first:
                 lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL

            2. Stash the LUKS passphrase where disko expects it (format-time only,
               NOT used at boot — boot prompts interactively):
                 echo -n 'your-passphrase' > /tmp/secret.key

            3. Partition + format + mount at /mnt (DESTRUCTIVE — wipes the disk):
                 just disko-format

            4. Install the system onto /mnt:
                 just install

            5. Reboot, then log in and finish:
                 just switch

          Notes:
            * The host mounts in modules/hosts/igloo.nix are hand-written and pin
              specific LUKS UUIDs. A fresh disko run creates NEW UUIDs, so update
              those (and /boot's) to match the new disk before/after first switch.
            * Run `just` to list every recipe.
          EOF
        '';
      };
    };
}
