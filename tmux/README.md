# Tmux Dotfiles

## Install

```sh
set -eu

DOTFILES_DIR="${DOTFILES_DIR:-$PWD}"

TMUX_PLUGIN_DIR="$HOME/.config/tmux/plugins"
TPM_DIR="$TMUX_PLUGIN_DIR/tpm"

mkdir -p "$HOME/.config/tmux" "$TMUX_PLUGIN_DIR"
ln -sf "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

tmux start-server \; \
  set-environment -g TMUX_PLUGIN_MANAGER_PATH "$TMUX_PLUGIN_DIR/" \; \
  source-file "$HOME/.config/tmux/tmux.conf"
"$TPM_DIR/bin/install_plugins"
```

The top-level `install.sh` performs these steps automatically when `tmux` and
`git` are available.

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

The config is set up so detaching from tmux leaves sessions and pane processes
running:

- `destroy-unattached` is off, so detached sessions are kept alive.
- `exit-empty` is off, so the tmux server is not torn down just because no
  sessions are present.
- `tmux-continuum` autosaves every 15 minutes.
- `tmux-continuum` restores the last saved environment when a fresh tmux server
  starts.
- Boot autostart is off; start tmux manually after login.
- `tmux-resurrect` can still restore sessions manually with `prefix + R`.

Tmux detach preserves live processes only while the tmux server is still
running. After a reboot, crash, `kill-server`, or OS-level user-process cleanup,
restore means recreating panes and rerunning supported commands, not continuing
the exact old process memory.

Restored panes include structure, working directories, pane contents, common
interactive tools, and Codex panes restored through `zsh -ic cx`.
