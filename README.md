# dotfiles
Settings I want between different unix type installations.

## Tmux auto-reload on config save

You can have tmux automatically reload your `tmux.conf` whenever you save it (no plugin folder needed).  
Add the following block to the bottom of your `~/.config/tmux/tmux.conf`:

```tmux
bind r source-file ~/.config/tmux/tmux.conf \
  \; display-message "tmux.conf reloaded"

# Auto-reload tmux config on save (requires inotifywait)
if-shell "command -v inotifywait >/dev/null" \
  "run-shell -b 'while inotifywait -e close_write ~/.config/tmux/tmux.conf; do \
      tmux source-file ~/.config/tmux/tmux.conf; \
      tmux display-message \"tmux.conf auto-reloaded\"; \
    done'"

run '~/.tmux/plugins/tpm/tpm'
```

### One-time setup

Install the required `inotifywait` utility:

```bash
# Debian/Ubuntu
sudo apt-get install inotify-tools

# macOS (with Homebrew)
brew install inotify-tools
```
