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

            # Snapshot mode keeps the disk pristine across runs (writes go to
            # a temporary overlay). Set SNAPSHOT=0 to commit changes to $DISK.
            SNAPSHOT_ARG=()
            if [[ "''${SNAPSHOT:-1}" != "0" ]]; then
              SNAPSHOT_ARG=(-snapshot)
            fi

            qemu-system-x86_64 \
              -name lunatix \
              -machine type=q35,accel=kvm \
              -cpu host \
              -smp "$CPUS" \
              -m "$MEMORY" \
              -enable-kvm \
              -drive "if=pflash,format=raw,readonly=on,file=${ovmfCode}" \
              -drive "if=pflash,format=raw,file=${ovmfVars}" \
              -drive "file=$DISK,if=virtio,format=qcow2" \
              -device virtio-vga \
              -netdev user,id=net0 \
              -device virtio-net,netdev=net0 \
              -boot menu=on \
              -vga none \
              "''${SNAPSHOT_ARG[@]}" \
              ''${ISO:+-drive "file=$ISO,media=cdrom"} \
              # EXTRA_QEMU_ARGS is intentionally unquoted: it passes multiple
              # qemu flags as separate argv entries (word splitting is the point).
              # shellcheck disable=SC2086
              $EXTRA_QEMU_ARGS \
              "$@"
          '';
      };
    };
}
