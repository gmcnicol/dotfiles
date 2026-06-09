# Tmux Dotfiles

## Install

```sh
set -eu

DOTFILES_DIR="${DOTFILES_DIR:-$PWD}"

mkdir -p "$HOME/.config/tmux" "$HOME/.tmux/plugins"
ln -sf "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
```

Start tmux, then press `Ctrl-Space` followed by `I` to install plugins.

## Shell Commands

| Command | Action |
| ------- | ------ |
| `t` | Attach/create a session for the current Git repo, or `main` from `$HOME` |
| `t dotfiles` | Attach/create `dotfiles`, searching `~/src`, `~/work`, `~/code`, `~/dev`, `~/Developer`, `~/Sites`, then `~` |
| `t dotfiles ~/src/dotfiles` | Attach/create `dotfiles` at a specific directory |
| `tt` | Fuzzy-pick existing sessions and common project directories |
| `tl` | List sessions and common project directories |

`t <Tab>` completes existing tmux sessions and common project directory names.

## Keybindings

The prefix is `Ctrl-Space`.

| Key | Action |
| --- | ------ |
| `prefix + I` | Install TPM plugins |
| `prefix + r` | Reload `~/.config/tmux/tmux.conf` |
| `prefix + S` | Save session state with tmux-resurrect |
| `prefix + R` | Restore saved session state with tmux-resurrect |
| `prefix + s` | Switch sessions/windows/panes with the built-in tree chooser |
| `prefix + \|` | Split side-by-side in the current directory |
| `prefix + -` | Split stacked in the current directory |
| `prefix + c` | New window in the current directory |
| `Ctrl-h/j/k/l` | Move between tmux panes, passing through to Vim/Neovim |
| `prefix + H/J/K/L` | Resize the active pane |
| `prefix + [` | Enter copy mode |
| `v` in copy mode | Start selection |
| `y` or `Enter` in copy mode | Copy selection to the system clipboard when available |
| `prefix + q` | Show pane numbers |

## Persistence

The config uses conservative persistence:

- `tmux-continuum` autosaves every 15 minutes.
- `tmux-resurrect` restores sessions manually with `prefix + R`.
- Automatic restore on tmux start is off.
- Boot autostart is off.

Restored panes include structure, working directories, pane contents, common
interactive tools, and Codex panes restored through `zsh -ic cx`.
