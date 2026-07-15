#!/bin/sh
set -eu

workspace=$(aerospace list-workspaces --focused --format '%{workspace}')
apps=$(aerospace list-windows --all --format '%{app-name}|%{workspace}' |
  awk -F '|' -v workspace="$workspace" '$2 != workspace { print $1 }' |
  sort -u)
[ -n "$apps" ] || exit 0

app=$(/usr/bin/osascript - "$apps" <<'APPLESCRIPT'
on run argv
  set apps to paragraphs of item 1 of argv
  tell application "Finder"
    activate
    set picked to choose from list apps with title "Pull app" with prompt "Move app to the current workspace"
  end tell
  if picked is false then return ""
  return item 1 of picked
end run
APPLESCRIPT
)
[ -n "$app" ] || exit 0

aerospace list-windows --all --format '%{window-id}|%{app-name}|%{workspace}' |
  awk -F '|' -v app="$app" -v workspace="$workspace" '$2 == app && $3 != workspace { print $1 }' |
  while IFS= read -r window; do
    aerospace move-node-to-workspace --window-id "$window" "$workspace"
  done
