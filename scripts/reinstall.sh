#!/usr/bin/env bash
# reinstall.sh — interactive NixOS (re)install from the minimal ISO.
#
# Run after cloning lunatix on a fresh minimal NixOS ISO (in the bootstrap
# dev shell: `nix develop` or `just bootstrap`). It:
#   1. asks hostname / username / arch
#   2. runs nixos-facter -> <host>-facter.json, wires hardware.facter.reportPath
#   3. lets you pick the target disk (from facter) + disko layout
#   4. picks which optional aspects to include (core ones locked on)
#   5. generates modules/hosts/<host>.nix, prints it for review, then runs
#      disko-format (DESTRUCTIVE) + nixos-install
#
# Requires the bootstrap toolbox: gum, disko, disko-install, nixos-facter,
# cryptsetup, btrfs-progs (all in modules/flake/devshell.nix).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTS_DIR="$HERE/modules/hosts"
HARDWARE_DIR="$HERE/modules/community/lix/hardware"
USER_DIR="$HERE/modules/user"

gum_style() { gum style --foreground 213 --bold --border rounded --padding "0 2" "$@"; }

# ---------- 1. identity ----------
gum_style "lunatix NixOS (re)install"

HOSTNAME="$(gum input --placeholder "hostname (e.g. igloo)" --prompt "hostname: ")"
USERNAME="$(gum input --value "${USER:-lunixose}" --prompt "username: ")"
ARCH="$(gum choose "x86_64-linux" "aarch64-linux" --header "arch (from uname -m: $(uname -m))" --cursor "> ")"
case "$ARCH" in
  x86_64-linux) NIX_ARCH=x86_64-linux ;;
  aarch64-linux) NIX_ARCH=aarch64-linux ;;
esac

[ -n "$HOSTNAME" ] || { echo "error: hostname required" >&2; exit 1; }

# ---------- 2. facter ----------
HOST_FACTER="$HARDWARE_DIR/$HOSTNAME-facter.json"
if [ -f "$HOST_FACTER" ]; then
  echo "facter report exists: $HOST_FACTER"
  if ! gum confirm "Re-run nixos-facter?" --affirmative "Re-run" --negative "Keep"; then
    SKIP_FACTER=1
  fi
fi
if [ "${SKIP_FACTER:-0}" != "1" ]; then
  gum spin --spinner dot --title "running nixos-facter (hardware report)…" -- \
    nixos-facter -o "$HOST_FACTER"
  echo "wrote $HOST_FACTER"
fi

# ---------- 3. disk + layout ----------
# Extract whole-disk by-id paths from facter.json (prefer the stable
# /dev/disk/by-id/* name). Filters: only /hardware/disk[] entries, drop
# partition suffixes (_-partN / -partN) and non-disk by-id (usb-, input-).
mapfile -t DISKS < <(python3 -c '
import json,sys,re
d=json.load(open(sys.argv[1]))
def walk(o):
    if isinstance(o,dict):
        for k,v in o.items():
            if k=="unix_device_names" and isinstance(v,list):
                for n in v:
                    if "/by-id/" in n and not n.startswith("/dev/disk/by-id/usb-") \
                       and not n.startswith("/dev/input/") \
                       and not re.search(r"-part\d+$|_\d+$", n):
                        yield n
            else: yield from walk(v)
    elif isinstance(o,list):
        for i in o: yield from walk(i)
for n in sorted(set(walk(d))): print(n)
' "$HOST_FACTER")

if [ "${#DISKS[@]}" -eq 0 ]; then
  echo "error: no /dev/disk/by-id device found in facter.json" >&2
  echo "falling back to manual device entry" >&2
  DISK_DEVICE="$(gum input --placeholder "/dev/sda" --prompt "device: ")"
else
  DISK_DEVICE="$(gum choose "${DISKS[@]}" --header "target disk (DESTRUCTIVE)" --cursor "> ")"
fi

LAYOUT="$(gum choose \
  "desktop" \
  "server" \
  "simple-efi" \
  "swap" \
  "luks-interactive" \
  "tmpfs-root" \
  --header "disko layout" \
  --cursor "> ")"

DISK_NAME="main"

# ---------- 4. aspects ----------
# Core aspects are locked on (can't skip disko-layout -> that bricks boot).
CORE_ASPECTS="settings disko-$LAYOUT lig/agenix"
OPTIONAL_ASPECTS="$(gum choose --no-limit \
  "minimal" "tools" "development" "communication" "gaming" \
  "system" "hyprland" "greetd" "zenwser" "doomacs" "obs" \
  "sioyek" "flameshot" "mpv" "nixcord" "kanata" \
  --header "optional aspects (space to toggle, enter to continue; 'minimal' = core desktop)" \
  --cursor "> ")"

# ---------- 5. user aspect ----------
USER_ASPECT=""
if [ "$USERNAME" != "lunixose" ] || [ ! -f "$USER_DIR/lunixose.nix" ]; then
  echo "note: user aspect for '$USERNAME' needs creation (see modules/user/lunixose.nix for the pattern)."
  gum confirm "Create user aspect modules/user/$USERNAME.nix?" --affirmative "Create" --negative "Skip" \
    && USER_ASPECT="$USERNAME" || USER_ASPECT=""
fi

# ---------- 6. generate host file ----------
HOST_FILE="$HOSTS_DIR/$HOSTNAME.nix"
cat > "$HOST_FILE" <<EOF
{ __findFile, ... }: {
  den.hosts.$NIX_ARCH.$HOSTNAME.users.$USERNAME = { };

  den.aspects.$HOSTNAME = {
    includes = [
EOF
for a in $CORE_ASPECTS; do echo "      <$a>" >> "$HOST_FILE"; done
for a in $OPTIONAL_ASPECTS; do echo "      <$a>" >> "$HOST_FILE"; done
[ -n "$USER_ASPECT" ] && echo "      <den/define-user> <den/primary-user>" >> "$HOST_FILE"
cat >> "$HOST_FILE" <<EOF
    ];

    disk = {
      name = "$DISK_NAME";
      device = "$DISK_DEVICE";
      layout = "$LAYOUT";
    };

    nixos = { ... }: {
      hardware.facter.reportPath = ../community/lix/hardware/$HOSTNAME-facter.json;
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    };
  };
}
EOF

gum_style "generated $HOST_FILE — review before proceeding"
cat "$HOST_FILE"
if ! gum confirm "Accept this host file? (prints only, no commit)"; then
  echo "aborted — $HOST_FILE written but not applied. Edit then re-run disko/nixos-install manually."
  exit 1
fi

# ---------- 7. LUKS passphrase + DESTRUCTIVE disko-format ----------
if [ "$LAYOUT" = "desktop" ] || [ "$LAYOUT" = "luks-interactive" ]; then
  if [ "$LAYOUT" = "desktop" ]; then
    gum input --password --placeholder "LUKS passphrase (format-time only; boot prompts)" \
      --prompt "passphrase: " > /tmp/secret.key
    echo >> /tmp/secret.key
  fi
fi

gum_style "WARNING: disko-format wipes $DISK_DEVICE (layout: $LAYOUT)"
gum confirm "Run disko-format now? (DESTRUCTIVE)" --affirmative "DESTROY & FORMAT" --negative "Abort" \
  || { echo "aborted — no changes made to disk"; exit 1; }

sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake ".#$HOSTNAME"

# ---------- 8. install ----------
gum_style "installing NixOS to /mnt ($HOSTNAME)"
sudo nixos-install --flake ".#$HOSTNAME" --no-root-passwd

gum_style "done — reboot into the installed system"
echo "After reboot:"
echo "  cd ~/Proj/lunatix && just switch"
echo "  git add modules/hosts/$HOSTNAME.nix modules/community/lix/hardware/$HOSTNAME-facter.json && git commit"
