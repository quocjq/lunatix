#!/usr/bin/env bash
# qemu-iso.sh — fetch the minimal NixOS installer ISO, build the qemu runner,
# and boot the installer (or the installed system).
#
# Usage:
#   scripts/qemu-iso.sh fetch            # download ~/Downloads/nixos-minimal.iso
#   scripts/qemu-iso.sh install          # fetch + build + boot installer (throwaway)
#   scripts/qemu-iso.sh boot             # boot the installed qcow2 (no ISO)
set -euo pipefail

ISO_DIR="${ISO_DIR:-$HOME/Downloads}"
ISO_URL="https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso"
ISO="$ISO_DIR/nixos-minimal.iso"
DISK="${DISK:-$ISO_DIR/install.qcow2}"
SNAPSHOT="${SNAPSHOT:-1}"

# `file` is not on PATH in the nix dev shell — resolve via nixpkgs.
if command -v file >/dev/null 2>&1; then
  FILE_BIN="$(command -v file)"
else
  FILE_BIN="$(nix --extra-experimental-features 'nix-command flakes' \
    build --no-link --print-out-paths nixpkgs#file 2>/dev/null | tail -1)/bin/file"
fi

build_runner() {
  nix --extra-experimental-features 'nix-command flakes' build .#qemu --no-link \
    --print-out-paths 2>/dev/null | tail -1
}

fetch_iso() {
  mkdir -p "$ISO_DIR"
  if [ -f "$ISO" ] && [ "${FORCE:-0}" = "0" ]; then
    # Already have it — verify it's still an ISO, else redownload.
    if "$FILE_BIN" -b "$ISO" | grep -qE "ISO 9660|DOS/MBR"; then
      echo "ISO already present: $ISO (FORCE=1 to redownload)"
      return 0
    fi
    echo "==> Existing file is not an ISO, re-downloading…"
  fi
  echo "==> Downloading minimal NixOS ISO (1.7G)…"
  curl -fL -o "$ISO" "$ISO_URL"
  if ! "$FILE_BIN" -b "$ISO" | grep -qE "ISO 9660|DOS/MBR"; then
    echo "error: $ISO is not an ISO (channel moved?)" >&2
    "$FILE_BIN" -b "$ISO"
    exit 1
  fi
  echo "ISO ready: $ISO"
}

case "${1:-fetch}" in
  fetch)
    fetch_iso
    ;;
  install)
    fetch_iso
    RUNNER="$(build_runner)"
    # SNAPSHOT=0 is REQUIRED here: SNAPSHOT=1 (default) would write the
    # installer's disk changes to a throwaway overlay that is discarded on
    # VM exit — the qcow2 stays blank and qemu-boot lands in emergency mode.
    echo "==> Booting installer (SNAPSHOT=0 — install persists to $DISK)…"
    SNAPSHOT="0" DISK="$DISK" ISO="$ISO" "$RUNNER/bin/qemu"
    echo "==> Done. Reboot into the installed system:"
    echo "    scripts/qemu-iso.sh boot"
    ;;
  boot)
    RUNNER="$(build_runner)"
    echo "==> Booting installed system (SNAPSHOT=$SNAPSHOT, disk=$DISK)…"
    SNAPSHOT="$SNAPSHOT" DISK="$DISK" "$RUNNER/bin/qemu"
    ;;
  *)
    echo "usage: $0 {fetch|install|boot}" >&2
    exit 1
    ;;
esac
