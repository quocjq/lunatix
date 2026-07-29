#!/usr/bin/env bash
#
# Toggles the Hyprland `type` submap based on whether the active workspace
# is empty. When empty (zero regular toplevel windows), the submap engages
# so the per-letter binds defined in modules/lunix/hyprland/config/bind.nix
# open the noctalia launcher. Otherwise the submap resets and letter keys
# flow through to the focused window with no interception.
#
# Listens to Hyprland's `.socket2` via socat. Workspace-change events carry
# a JSON payload with a `windows` count that we pipe through jq.
#
# Started by Hyprland's `exec-once` in bind.nix.

set -euo pipefail

instance="${HYPRLAND_INSTANCE_SIGNATURE:-}"
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
sock="${runtime}/hypr/${instance}/.socket2"

if [ -z "$instance" ] || [ ! -S "$sock" ]; then
  echo "type-submap-watcher: Hyprland socket not found (${sock}); exiting" >&2
  exit 1
fi

log() { printf 'type-submap-watcher: %s\n' "$*" >&2; }

apply() {
  local wins="$1"
  if [ "$wins" = "0" ]; then
    hyprctl dispatch submap type  >/dev/null 2>&1 || true
    log "submap -> type (empty ws)"
  else
    hyprctl dispatch submap reset >/dev/null 2>&1 || true
    log "submap -> reset (wins=$wins)"
  fi
}

# Set initial state once so the right submap is active on Hyprland start.
initial_wins="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.windows // 0' || echo 0)"
apply "$initial_wins"

# Stream events. Format: "eventname>>payload\n" — workspace events include JSON.
socat -u "UNIX-CONNECT:${sock}" - 2>/dev/null \
  | while IFS= read -r line; do
      case "$line" in
        workspace\>\>*)
          payload="${line#workspace>>}"
          wins="$(printf '%s' "$payload" | jq -r '.windows // 0' 2>/dev/null || echo 0)"
          apply "$wins"
          ;;
        focusedmon\>\>*|monitoradded\>\>*|monitorremoved\>\>*)
          # Monitor topology changed; the active workspace may have moved.
          wins="$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.windows // 0' || echo 0)"
          apply "$wins"
          ;;
      esac
    done

log "socket closed; exiting"