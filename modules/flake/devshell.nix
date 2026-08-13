# Bootstrap devshell — the toolbox you drop into on a fresh NixOS installer
# after git cloning this repo. `nix develop` here gives you every CLI the
# reinstall needs (gum TUI, disko, the partition/luks/fs tools it shells out
# to, the nixos-install family, agenix for secrets, facter, plus git/just)
# without polluting the installed system's package set.
#
#   Fresh boot -> nix-shell -p git -> git clone <repo> -> cd lunatix
#   nix develop            # you are now here
#   just reinstall         # interactive install (see scripts/reinstall.sh)
#
# The runbook printed by shellHook mirrors the reinstall flow:
# disko formats AND manages the running system's mounts/LUKS/swap via the
# NixOS module (`disko.enableConfig = true`). Disk layouts live in
# modules/community/lix/diskos/ — each host includes the one it wants.
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
          python3 # reinstall.sh parses facter.json (disk by-id extraction)

          # disko itself: `disko --mode destroy,format,mount <flake>#<host>` or
          # the one-shot `disko-install`. Pulled from the pinned input so it
          # matches flake.lock rather than the installer's channel.

          # Tools disko shells out to while formatting the chosen layout.
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
          │ Tools: gum, disko, disko-install, cryptsetup, btrfs-progs,        │
          │        gptfdisk, nixos-install-tools, nixos-facter, agenix,       │
          │        git, just                                                  │
          └───────────────────────────────────────────────────────────────────┘

          Fresh install / reinstall, driven by `just reinstall`
          (scripts/reinstall.sh — interactive gum flow):

            1. just reinstall
               • hostname / username / arch
               • nixos-facter -> modules/community/lix/hardware/<host>-facter.json
               • pick target disk (from facter by-id) + disko layout
               • pick optional aspects (core: settings/disko-*/lig/agenix are
                 locked on and cannot be skipped)
               • generated host file is PRINTED for review before any disk change
            2. it prompts the LUKS passphrase, then runs disko-format
               (DESTRUCTIVE) + nixos-install
            3. reboot, then log in and finish:
                 just switch

          Manual path (same tools, step by step):
            1. lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL    # inspect the target
            2. echo -n 'passphrase' > /tmp/secret.key  # desktop layout only
            3. just disko-format                        # DESTRUCTIVE
            4. just install
            5. just switch                              # after reboot

          Notes:
            * Disk layouts live in modules/community/lix/diskos/<name>.nix
              (den.aspects."disko-<name>"): desktop (LUKS+btrfs+swap),
              server (plain), simple-efi, swap, luks-interactive, tmpfs-root.
              Hosts include the layout they want (<disko-desktop> etc).
            * A NEW host must be a recipient in _secrets/secrets.nix (agenix)
              before the first switch; commit its facter.json too.
            * On an existing disk whose swap partition lacks a partlabel, run
              `sudo sgdisk -c 3:swap /dev/nvme0n1` once before the first rebuild.
            * Run `just` to list every recipe.
          EOF
        '';
      };
    };
}
