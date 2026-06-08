#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: ./install.sh [--force]

Links this repo into the expected config locations:
  ~/.config/ghostty/config.ghostty -> ghostty/config.ghostty
  ~/.config/tmux/tmux.conf -> tmux/tmux.conf
  ~/.config/nvim           -> nvim
  ~/.config/zsh/.zshrc     -> zsh/.zshrc
  ~/.config/zsh/.zshenv    -> zsh/.zshenv
  ~/.zshenv                -> ~/.config/zsh/.zshenv

It also creates ~/.zshrc.local and appends a source line for the shared zsh
config to ~/.zshrc.

Use --force to move conflicting files/directories aside with a timestamped
.bak suffix before linking.
EOF
}

force=false
case "${1:-}" in
  "")
    ;;
  --force)
    force=true
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

repo_dir=$(CDPATH= cd "$(dirname "$0")" && pwd -P)
backup_suffix=".bak.$(date +%Y%m%d%H%M%S)"

info() {
  printf '%s\n' "$*"
}

ensure_parent() {
  mkdir -p "$(dirname "$1")"
}

backup_existing() {
  path=$1

  if [ "$force" = true ]; then
    info "Backing up $path -> $path$backup_suffix"
    mv "$path" "$path$backup_suffix"
  else
    printf 'Refusing to overwrite %s. Re-run with --force to back it up first.\n' "$path" >&2
    exit 1
  fi
}

link_path() {
  src=$1
  dest=$2

  ensure_parent "$dest"

  if [ -L "$dest" ]; then
    current=$(readlink "$dest")
    if [ "$current" = "$src" ]; then
      info "Already linked: $dest -> $src"
      return
    fi
    rm "$dest"
  elif [ -e "$dest" ]; then
    backup_existing "$dest"
  fi

  ln -s "$src" "$dest"
  info "Linked: $dest -> $src"
}

append_once() {
  line=$1
  file=$2
  heading=$3

  touch "$file"
  if grep -Fqx "$line" "$file"; then
    info "Already configured: $file"
    return
  fi

  {
    printf '\n%s\n' "$heading"
    printf '%s\n' "$line"
  } >> "$file"
  info "Updated: $file"
}

mkdir -p "$HOME/.config/ghostty" "$HOME/.config/tmux" "$HOME/.config/zsh" "$HOME/.tmux/plugins"

link_path "$repo_dir/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
link_path "$repo_dir/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link_path "$repo_dir/nvim" "$HOME/.config/nvim"
link_path "$repo_dir/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
link_path "$repo_dir/zsh/.zshenv" "$HOME/.config/zsh/.zshenv"
link_path "$HOME/.config/zsh/.zshenv" "$HOME/.zshenv"

touch "$HOME/.zshrc.local"
chmod 600 "$HOME/.zshrc.local"
append_once 'source "$HOME/.config/zsh/.zshrc"' "$HOME/.zshrc" '# Personal zsh customisations'

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  if command -v git >/dev/null 2>&1; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  else
    info "git not found; install TPM manually at ~/.tmux/plugins/tpm"
  fi
else
  info "Already installed: ~/.tmux/plugins/tpm"
fi

info
info "Done. In tmux, press Ctrl-Space then I to install/update plugins."
