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

## Neovim setup

These dotfiles include a minimal [lazy.nvim](https://github.com/folke/lazy.nvim) configuration.  The plugin list focuses on Java development and general quality-of-life enhancements.

### Included plugins

- `mason.nvim`, `mason-lspconfig.nvim` and `nvim-lspconfig` for installing and configuring language servers
- `mfussenegger/nvim-jdtls` for Java LSP support
- `hrsh7th/nvim-cmp` with buffer, path and LuaSnip completion sources
- `L3MON4D3/LuaSnip` and `rafamadriz/friendly-snippets` for snippets
- `nvim-treesitter` with `nvim-treesitter-context`
- `telescope.nvim` and `neo-tree.nvim` for navigation
- `nvim-dap`, `nvim-dap-ui` and virtual text (plus the Java debug adapter) for debugging
- `neotest` with the JUnit adapter
- `null-ls.nvim` with formatters and linters like `google-java-format` and Checkstyle
- `harpoon` v2 and `git-worktree.nvim`
- `gitsigns.nvim`, `vim-commentary` and `vim-sleuth`

Most of these rely on `nvim-lua/plenary.nvim`, which is included automatically.
