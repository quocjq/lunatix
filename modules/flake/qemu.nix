# modules/flake/qemu.nix
#
# Build a standalone qemu-kvm runner for igloo. Unlike vm.nix (which uses
# NixOS's built-in `system.build.vm` and shares the host /nix/store via an
# overlay), this module produces a script that boots the system on a
# separate qcow2 disk image. Useful for:
#
#   - testing disk installs (mimics real hardware)
#   - validating the UEFI boot chain (uses OVMF firmware directly)
#   - rehearsing nixos-install before touching real hardware
#   - booting the install ISO with `qemu -ISO path/to/installer.iso`
#
# Build with:  nix build .#qemu
# Run with:    ./result/bin/qemu
# Override:    DISK=foo.qcow2 MEMORY=8G CPUS=8 ./result/bin/qemu
{
  perSystem =
    { pkgs, ... }:
    {
      packages.qemu = pkgs.writeShellApplication {
        name = "qemu";
        runtimeInputs = [
          pkgs.qemu
          pkgs.coreutils
          pkgs.gnused
          pkgs.gnugrep
        ];
        text =
          let
            ovmfFd = pkgs.OVMFFull.fd;
            ovmfCode = "${ovmfFd}/FV/OVMF_CODE.fd";
            ovmfVars = "${ovmfFd}/FV/OVMF_VARS.fd";
          in
          ''
            set -euo pipefail

            DISK="''${DISK:-lunatix.qcow2}"
            MEMORY="''${MEMORY:-4G}"
            CPUS="''${CPUS:-4}"
            ISO="''${ISO:-}"
            EXTRA_QEMU_ARGS="''${EXTRA_QEMU_ARGS:-}"

            if [[ ! -f "$DISK" ]]; then
              echo "==> Creating new qcow2 disk: $DISK (64G)"
              qemu-img create -f qcow2 "$DISK" 64G
            fi

            # OVMF_VARS.fd in the nix store is read-only, but QEMU opens the
            # writable pflash drive for write. Copy it next to the disk so the
            # VM's boot-variable store is actually writable.
            VARS_DIR="$(dirname "$DISK")"
            VARS_FILE="$VARS_DIR/OVMF_VARS.fd"
            if [[ ! -f "$VARS_FILE" ]]; then
              echo "==> Copying writable OVMF_VARS.fd -> $VARS_FILE"
              cp ${ovmfVars} "$VARS_FILE"
              chmod u+w "$VARS_FILE"
            fi

            # Snapshot mode keeps the disk pristine across runs (writes go to
            # a temporary overlay). Set SNAPSHOT=0 to commit changes to $DISK.
            SNAPSHOT_ARG=()
            if [[ "''${SNAPSHOT:-1}" != "0" ]]; then
              SNAPSHOT_ARG=(-snapshot)
            fi

            # Boot order: when an ISO is attached, boot the CD-ROM first (the
            # disk is empty on first install — booting it lands in the NixOS
            # rescue shell: bash 5.3, no sudo). Otherwise boot the disk.
            if [[ -n "$ISO" ]]; then
              BOOT_ARG=(-boot "order=d,menu=on")
            else
              BOOT_ARG=(-boot "order=c,menu=on")
            fi

            # EXTRA_QEMU_ARGS / "$@" are intentionally unquoted so extra flags
            # pass as separate argv entries (word splitting is the point).
            # shellcheck disable=SC2086
            qemu-system-x86_64 \
              -name lunatix \
              -machine type=q35,accel=kvm \
              -cpu host \
              -smp "$CPUS" \
              -m "$MEMORY" \
              -enable-kvm \
              -drive "if=pflash,format=raw,readonly=on,file=${ovmfCode}" \
              -drive "if=pflash,format=raw,file=$VARS_FILE" \
              -drive "file=$DISK,if=virtio,format=qcow2" \
              -device virtio-vga \
              -netdev user,id=net0 \
              -device virtio-net,netdev=net0 \
              "''${BOOT_ARG[@]}" \
              "''${SNAPSHOT_ARG[@]}" \
              ''${ISO:+-drive "file=$ISO,media=cdrom,format=raw,readonly=on"} \
              $EXTRA_QEMU_ARGS \
              "$@"
          '';
      };
    };
}
