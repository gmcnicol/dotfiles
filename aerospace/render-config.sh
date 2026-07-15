#!/bin/sh
set -eu

config_dir=$(CDPATH='' cd "$(dirname "$0")" && pwd -P)
host=${AEROSPACE_HOST:-$(hostname -s)}
routes="$config_dir/hosts/$host.toml"
destination=${AEROSPACE_CONFIG_PATH:-$HOME/.config/aerospace/aerospace.toml}
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

if [ ! -f "$routes" ]; then
  routes=
fi

awk -v routes="$routes" '
  $0 == "# __HOST_ROUTES__" {
    if (routes != "") {
      while ((getline line < routes) > 0) print line
      close(routes)
    }
    next
  }
  { print }
' "$config_dir/aerospace.toml" > "$tmp"

mkdir -p "$(dirname "$destination")"
rm -f "$destination"
mv "$tmp" "$destination"
trap - EXIT
printf 'Rendered AeroSpace config for %s: %s\n' "$host" "$destination"
