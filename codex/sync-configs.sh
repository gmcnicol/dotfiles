#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  sync-configs.sh --machine NAME [--dest DIRECTORY] [--remote HOST]
                  [--remote-dir DIRECTORY] [--dry-run]

Machine names:
  macos-work-laptop | macos-personal-macmini | omarchy-laptop | ubuntu-server

By default, the redacted snapshot is uploaded with rsync over SSH to
gareth@nuc:/home/gareth/src/dotfiles/.
EOF
}

machine=""
dest="$(mktemp -d "${TMPDIR:-/tmp}/codex-config-XXXXXX")"
dest_is_temporary=1
remote="gareth@nuc"
remote_dir="/home/gareth/src/dotfiles"
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --machine) machine="${2:?missing value for --machine}"; shift 2 ;;
    --dest) dest="${2:?missing value for --dest}"; dest_is_temporary=0; shift 2 ;;
    --remote) remote="${2:?missing value for --remote}"; shift 2 ;;
    --remote-dir) remote_dir="${2:?missing value for --remote-dir}"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

cleanup() {
  if (( dest_is_temporary )); then
    rm -rf -- "$dest"
  fi
}
trap cleanup EXIT

if [[ -z "$machine" ]]; then
  if [[ ! -t 0 ]]; then
    echo "--machine is required in non-interactive use." >&2
    usage >&2
    exit 2
  fi
  options=(
    macos-work-laptop
    macos-personal-macmini
    omarchy-laptop
    ubuntu-server
  )
  PS3="Select source machine: "
  select choice in "${options[@]}"; do
    if [[ -n "${choice:-}" ]]; then
      machine="$choice"
      break
    fi
    echo "Invalid selection." >&2
  done
fi

case "$machine" in
  macos-work-laptop|macos-personal-macmini|omarchy-laptop|ubuntu-server) ;;
  *) echo "Unsupported machine name: $machine" >&2; exit 2 ;;
esac

root="$dest"
codex_out="$root/codex/$machine"
docker_out="$root/docker-mcp/$machine"
manifest="$root/$machine-MANIFEST.txt"

if (( dry_run )); then
  echo "would verify SSH access to $remote"
else
  ssh -o BatchMode=yes "$remote" true
  mkdir -p "$codex_out" "$docker_out"
fi

declare -a sources=()
add_source() {
  local path="$1"
  if [[ -e "$path" ]]; then
    sources+=("$path")
  fi
}

add_source "$HOME/.codex/config.toml"
add_source "$HOME/.codex/AGENTS.md"
add_source "$HOME/.codex/skills"
add_source "$HOME/.codex/plugins"
add_source "$HOME/.codex/prompts"

add_source "$HOME/.docker/mcp"
add_source "$HOME/.docker/mcp.json"
add_source "$HOME/.docker/mcp.yaml"
add_source "$HOME/.docker/mcp.yml"
add_source "$HOME/.config/docker/mcp"
add_source "$HOME/.config/docker/mcp.json"
add_source "$HOME/.config/docker/mcp.yaml"
add_source "$HOME/.config/docker/mcp.yml"

copy_source() {
  local source="$1" out="$2"
  if (( dry_run )); then
    printf 'would copy %s -> %s\n' "$source" "$out"
    return
  fi

  mkdir -p "$out"
  if [[ -d "$source" ]]; then
    rsync -a \
      --exclude='auth.json' --exclude='credentials*' \
      --exclude='*.pem' --exclude='*.key' --exclude='*.p12' \
      --exclude='*.token' --exclude='*.secret' --exclude='.env' \
      --exclude='.env.*' "$source/" "$out/$(basename "$source")/"
  else
    case "$(basename "$source")" in
      auth.json|credentials*|*.pem|*.key|*.p12|*.token|*.secret|.env|.env.*)
        echo "skipping sensitive-looking file: $source" >&2
        ;;
      *) cp -p "$source" "$out/" ;;
    esac
  fi
}

for source in "${sources[@]}"; do
  case "$source" in
    "$HOME/.codex"/*) copy_source "$source" "$codex_out" ;;
    *) copy_source "$source" "$docker_out" ;;
  esac
done

if (( dry_run )); then
  echo "would upload $codex_out, $docker_out, and $manifest to $remote:$remote_dir/"
  echo "Dry run complete; no files were copied."
  exit 0
fi

{
  echo "Collection manifest: $machine"
  echo
  echo "Collected on: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "Hostname: $(hostname)"
  echo "OS: $(uname -a)"
  echo
  echo "Sources found:"
  echo
  if (( ${#sources[@]} == 0 )); then
    echo "No known configuration paths were found."
  else
    for source in "${sources[@]}"; do printf -- '%s\n' "$source"; done
  fi
  echo
  echo "Intentionally excluded:"
  echo
  echo "Credential files, tokens, private keys, and .env files."
} > "$manifest"

ssh -o BatchMode=yes "$remote" "mkdir -p '$remote_dir/codex/$machine' '$remote_dir/docker-mcp/$machine'"
rsync -az --exclude='auth.json' --exclude='credentials*' \
  --exclude='*.pem' --exclude='*.key' --exclude='*.p12' \
  --exclude='*.token' --exclude='*.secret' --exclude='.env' \
  --exclude='.env.*' "$codex_out/" "$remote:$remote_dir/codex/$machine/"
rsync -az --exclude='auth.json' --exclude='credentials*' \
  --exclude='*.pem' --exclude='*.key' --exclude='*.p12' \
  --exclude='*.token' --exclude='*.secret' --exclude='.env' \
  --exclude='.env.*' "$docker_out/" "$remote:$remote_dir/docker-mcp/$machine/"
rsync -az "$manifest" "$remote:$remote_dir/"

echo "Uploaded via SSH to: $remote:$remote_dir"
