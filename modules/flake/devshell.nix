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
# disko formats AND manages the running system's mounts/LUKS/swap via the
# NixOS module (`disko.enableConfig = true`). That module is the single
# source of truth for disk layout. The host module has no hand-written
# mounts.
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
        ];
        config = {
          allowUnfree = true;
        };
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          just
          git

          # disko itself: `disko --mode destroy,format,mount <flake>#igloo` or
          # the one-shot `disko-install`. Pulled from the pinned input so it
          # matches flake.lock rather than the installer's channel.

          # Tools disko shells out to while formatting the Latitude layout.
          inputs.disko.packages.${system}.disko
          inputs.disko.packages.${system}.disko-install
          # Present on the graphical ISO but not the minimal one, so pin them.
          cryptsetup # LUKS2 containers (root + swap)
          btrfs-progs # btrfs + subvolumes (home, nix)
          dosfstools # mkfs.vfat for the ESP
          gptfdisk # sgdisk / GPT labels (EFI, root)
          parted
          util-linux # wipefs, lsblk, blkid — inspect before you destroy

          # Install the closure onto the freshly mounted /mnt.
          nixos-install-tools # nixos-install, nixos-generate-config, nixos-enter

          # Secrets: the host decrypts *.age with its ssh host key, so the new
          # box must be a recipient in _secrets/secrets.nix before first switch.
          age
          openssh # ssh-keygen for a fresh host key / recipient pubkey
          inputs.agenix.packages.${system}.default

          # Reinstall script TUI (scripts/reinstall.sh): colorful prompts,
          # spinner, multi-select for aspects.
          gum
          nixos-facter # hardware report -> facter.json -> hardware.facter.reportPath
        ];

        shellHook = ''
          cat <<'EOF'
          ┌─ lunatix bootstrap shell ─────────────────────────────────────────┐
          │ Tools: disko, disko-install, cryptsetup, btrfs-progs, gptfdisk,   │
          │        nixos-install-tools, agenix, git, just                     │
          └───────────────────────────────────────────────────────────────────┘

          Reinstall on a fresh disk (Latitude 3250 layout), driven by `just`:

            1. Confirm the target disk still matches modules/disko/latitude3250.nix
               (device = /dev/disk/by-id/nvme-eui...). Inspect first:
                 lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL

            2. Stash the LUKS passphrase where disko expects it (format-time only,
               NOT used at boot, boot prompts interactively):
                 echo -n 'your-passphrase' > /tmp/secret.key

            3. Partition + format + mount at /mnt (DESTRUCTIVE, wipes the disk):
                 just disko-format

            4. Install the system onto /mnt:
                 just install

            5. Reboot, then log in and finish:
                 just switch

          Notes:
            * Disk layouts live in modules/community/lix/diskos/<name>.nix
              (den.aspects."disko-<name>"). Hosts include the layout they want:
              <disko-desktop> (LUKS+btrfs+swap) or <disko-server> (plain), etc.
              The layout aspect owns mounts, LUKS, and swap for that host.
            * On an existing disk whose swap partition lacks a partlabel, run
              `sudo sgdisk -c 3:swap /dev/nvme0n1` once before the first rebuild.
            * Run `just` to list every recipe.
          EOF
        '';
      };
    };
}
