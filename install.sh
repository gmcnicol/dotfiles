#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: ./install.sh [--force] [--headless]

Installs this repo into the expected config locations:
  ~/.config/aerospace/aerospace.toml from shared config plus host routes
  ~/.config/aerospace/pull-app.sh -> aerospace/pull-app.sh
  ~/.config/ghostty/config.ghostty -> ghostty/config.ghostty, when Ghostty is installed
  ~/.config/tmux/tmux.conf -> tmux/tmux.conf
  ~/.config/nvim           -> nvim
  ~/.config/zsh/.zshrc     -> zsh/.zshrc
  ~/.config/zsh/.zshenv    -> zsh/.zshenv
  ~/.zshenv                -> ~/.config/zsh/.zshenv
  ~/.codex/config.toml     from shared, profile, and machine layers
  ~/.codex/AGENTS.md       from shared Codex instructions
  ~/.config/codex/managed-machine for cx's machine-specific sync calls
  ~/.local/bin/codex-sync -> codex/managed/codex-sync

It also creates ~/.zshrc.local and appends a source line for the shared zsh
config to ~/.zshrc.

Set DOTFILES_INSTALL_GHOSTTY=1 to force Ghostty config installation on machines
where Ghostty is not installed.

The installer asks which Codex machine profile to use. Set CODEX_MANAGED_MACHINE
to supply it in non-interactive installs.

Use --headless to skip Ghostty config even when Ghostty is installed.

Use --force to move conflicting files/directories aside with a timestamped
.bak suffix before linking.
EOF
}

force=false
headless=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force=true
      ;;
    --headless)
      headless=true
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
  shift
done

repo_dir=$(CDPATH='' cd "$(dirname "$0")" && pwd -P)
backup_suffix=".bak.$(date +%Y%m%d%H%M%S)"
tmux_plugin_dir="$HOME/.config/tmux/plugins"
tpm_dir="$tmux_plugin_dir/tpm"

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

select_codex_machine() {
  if [ -n "${CODEX_MANAGED_MACHINE:-}" ]; then
    case "$CODEX_MANAGED_MACHINE" in
      macos-work-laptop|macos-personal-macmini|omarchy-laptop|ubuntu-server)
        printf '%s\n' "$CODEX_MANAGED_MACHINE"
        return
        ;;
      *)
        printf 'Unsupported CODEX_MANAGED_MACHINE: %s\n' "$CODEX_MANAGED_MACHINE" >&2
        return 1
        ;;
    esac
  fi

  if [ ! -t 0 ]; then
    printf 'CODEX_MANAGED_MACHINE is required in non-interactive installs.\n' >&2
    return 1
  fi

  while :; do
    printf '%s\n' \
      'Select this Codex machine:' \
      '  1) macos-work-laptop' \
      '  2) macos-personal-macmini' \
      '  3) omarchy-laptop' \
      '  4) ubuntu-server' >&2
    printf 'Selection: ' >&2
    IFS= read -r choice
    case "$choice" in
      1|macos-work-laptop) printf '%s\n' macos-work-laptop; return ;;
      2|macos-personal-macmini) printf '%s\n' macos-personal-macmini; return ;;
      3|omarchy-laptop) printf '%s\n' omarchy-laptop; return ;;
      4|ubuntu-server) printf '%s\n' ubuntu-server; return ;;
      *) printf 'Invalid selection.\n' >&2 ;;
    esac
  done
}

mkdir -p "$HOME/.config/aerospace" "$HOME/.config/codex" "$HOME/.config/tmux" "$HOME/.config/zsh" "$tmux_plugin_dir"

"$repo_dir/aerospace/render-config.sh"
link_path "$repo_dir/aerospace/pull-app.sh" "$HOME/.config/aerospace/pull-app.sh"

if [ "$headless" = true ] && [ "${DOTFILES_INSTALL_GHOSTTY:-}" != 1 ]; then
  info "Skipping Ghostty config in headless mode"
elif [ "${DOTFILES_INSTALL_GHOSTTY:-}" = 1 ] || command -v ghostty >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/ghostty"
  link_path "$repo_dir/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
else
  info "Skipping Ghostty config; use --headless to make this explicit or set DOTFILES_INSTALL_GHOSTTY=1 to force it"
fi

link_path "$repo_dir/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
link_path "$repo_dir/nvim" "$HOME/.config/nvim"
link_path "$repo_dir/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
link_path "$repo_dir/zsh/.zshenv" "$HOME/.config/zsh/.zshenv"
link_path "$HOME/.config/zsh/.zshenv" "$HOME/.zshenv"

touch "$HOME/.zshrc.local"
chmod 600 "$HOME/.zshrc.local"
append_once 'source "$HOME/.config/zsh/.zshrc"' "$HOME/.zshrc" '# Personal zsh customisations'

codex_machine=$(select_codex_machine)
printf '%s\n' "$codex_machine" > "$HOME/.config/codex/managed-machine"
chmod 600 "$HOME/.config/codex/managed-machine"
link_path "$repo_dir/codex/managed/codex-sync" "$HOME/.local/bin/codex-sync"

if ! command -v codex >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  npm install -g --loglevel=error @openai/codex@latest
fi

if command -v codex >/dev/null 2>&1; then
  CODEX_MANAGED_MACHINE="$codex_machine" "$repo_dir/codex/managed/codex-sync" update
else
  info "Skipping Codex configuration; install npm or Codex first"
fi

if [ ! -d "$tpm_dir" ]; then
  if command -v git >/dev/null 2>&1; then
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  else
    info "git not found; install TPM manually at $tpm_dir"
  fi
else
  info "Already installed: $tpm_dir"
fi

if [ -x "$tpm_dir/bin/install_plugins" ]; then
  if command -v tmux >/dev/null 2>&1; then
    tmux start-server \; \
      set-environment -g TMUX_PLUGIN_MANAGER_PATH "$tmux_plugin_dir/" \; \
      source-file "$HOME/.config/tmux/tmux.conf"
    "$tpm_dir/bin/install_plugins"
  else
    info "tmux not found; install tmux, then run $tpm_dir/bin/install_plugins"
  fi
fi

info
info "Done. Tmux plugins are installed when tmux is available."
