#!/usr/bin/env bash
#
# Hyprland letter-bind handler.
#
# On an empty workspace: open the noctalia launcher with the typed letter
# (and any letters typed within the TTL) pre-filled in the search field.
# On a workspace with a focused window: forward the key to that window.
#
# State lives in /tmp so it survives across bind invocations within a burst
# but resets after a short pause — no extra daemon required.

set -euo pipefail

key="${1:-}"
if [ -z "$key" ]; then
  exit 0
fi

# Per-Hyprland-instance buffer file keeps parallel sessions from clobbering.
instance="${HYPRLAND_INSTANCE_SIGNATURE:-default}"
buf="/tmp/noctalia-type-search-${instance}"
ttl=3   # seconds of inactivity before the buffer resets

now="$(date +%s)"
if [ -f "$buf" ]; then
  mtime="$(stat -c %Y "$buf")"
  if [ "$((now - mtime))" -lt "$ttl" ]; then
    query="$(cat "$buf" 2>/dev/null || true)"
  else
    query=""
  fi
else
  query=""
fi
query="${query}${key}"
printf '%s' "$query" > "$buf"

# Active workspace JSON: `.windows` is the count of regular (toplevel) windows.
# Layer-shell surfaces (including the launcher itself) are NOT counted.
wins="$(hyprctl activeworkspace -j 2>/dev/null | jq '.windows // 0')"

if [ "$wins" = "0" ]; then
  # Empty workspace — open / refresh the launcher with the accumulated query.
  noctalia msg panel-open launcher "$query"
else
  # Focused window — Hyprland consumed the original keystroke, re-send it.
  wtype "$key"
fi