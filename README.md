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

### Plugin cheat sheet

| Plugin | Sample commands |
| ------ | --------------- |
| **lazy.nvim** | `:Lazy` opens the plugin manager |
| **mason.nvim** | `:Mason` shows LSP/DAP installer |
| **nvim-lspconfig** | `:LspInfo` shows active servers |
| **nvim-jdtls** | `:JdtCompile` / `:JdtUpdateConfig` for Java projects |
| **nvim-cmp** | `<C-n>/<C-p>` navigate completion menu |
| **LuaSnip** | `<C-k>` expand or jump in a snippet |
| **telescope.nvim** | `:Telescope find_files` or `:Telescope live_grep` |
| **neo-tree.nvim** | `:Neotree toggle` file explorer |
| **harpoon** | plugin for quick file navigation |
| **git-worktree.nvim** | `:lua require('git-worktree').create_worktree()` |
| **gitsigns.nvim** | `:Gitsigns preview_hunk`, `:Gitsigns blame_line` |
| **vim-commentary** | `gcc` comment line, `gc` in visual mode |
| **nvim-treesitter** | `:TSUpdate`, `:TSInstall` parsers |
| **nvim-treesitter-context** | `:TSContextToggle` shows code context |
| **nvim-dap** | `:lua require('dap').continue()` etc. |
| **nvim-dap-ui** | `:lua require('dapui').toggle()` |
| **nvim-dap-virtual-text** | `:DapVirtualTextToggle` |
| **neotest** | `:lua require('neotest').run.run()` |
| **null-ls.nvim** | `:NullLsInfo` shows attached sources |
