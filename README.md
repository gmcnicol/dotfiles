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

You need ripgrep installed btw. 

These dotfiles include a minimal [lazy.nvim](https://github.com/folke/lazy.nvim) configuration.  The plugin list focuses on Java development and general quality-of-life enhancements.

### Included plugins

- `mason.nvim`, `mason-lspconfig.nvim` and `nvim-lspconfig` for installing and configuring language servers
- `mfussenegger/nvim-jdtls` for Java LSP support
- `hrsh7th/nvim-cmp` with buffer, path and LuaSnip completion sources
- `L3MON4D3/LuaSnip` and `rafamadriz/friendly-snippets` for snippets
- `nvim-treesitter` with `nvim-treesitter-context`
- `telescope.nvim` and `neo-tree.nvim` for navigation (the panel is disabled by default)
- `nvim-dap`, `nvim-dap-ui` and virtual text (plus the Java debug adapter) for debugging
- `neotest` with the JUnit adapter (`mike-deakin/neotest-junit`)
- `null-ls.nvim` with formatters and linters like `google-java-format` and Checkstyle
- `harpoon` v2 and `git-worktree.nvim`
- `gitsigns.nvim`, `vim-fugitive`, `vim-commentary` and `vim-sleuth`

Most of these rely on `nvim-lua/plenary.nvim`, which is included automatically.
LSP support is configured in `nvim/after/plugin/lsp.lua` where `gmm.lsp` is
required during startup.

### Plugin cheat sheet

| Plugin | Sample commands |
| ------ | --------------- |
| **lazy.nvim** | `:Lazy` opens the plugin manager |
| **mason.nvim** | `:Mason` shows LSP/DAP installer |
| **nvim-lspconfig** | `gd`/`gD`/`gi`/`gr` jump around code, `<C-S-f>` formats, `:LspInfo` shows active servers |
| **nvim-jdtls** | Java LSP starts automatically; `:JdtCompile` / `:JdtUpdateConfig` for Java projects |
| **nvim-cmp** | `<C-n>/<C-p>` navigate completion menu |
| **LuaSnip** | `<C-k>` expand or jump in a snippet |
| **telescope.nvim** | `<leader>pf` files, `<leader>pg` git files, `<leader>ps` grep string, `<leader>pws` grep word |
| **neo-tree.nvim** | `:Neotree toggle` file explorer (panel disabled) |
| **harpoon** | `<leader>a` mark, `<C-e>` menu, `<leader>h[1-9]` pick slot, `<C-S-P>/<C-S-N>` cycle |
| **git-worktree.nvim** | `:lua require('git-worktree').create_worktree()` |
| **gitsigns.nvim** | `:Gitsigns preview_hunk`, `:Gitsigns blame_line` |
| **vim-fugitive** | `:Git` to run Git commands |
| **vim-commentary** | `gcc` comment line, `gc` in visual mode |
| **nvim-treesitter** | `:TSUpdate`, `:TSInstall` parsers |
| **nvim-treesitter-context** | `:TSContextToggle` shows code context |
| **nvim-dap** | `:lua require('dap').continue()` etc. |
| **nvim-dap-ui** | `:lua require('dapui').toggle()` |
| **nvim-dap-virtual-text** | `:DapVirtualTextToggle` |
| **neotest** | `:lua require('neotest').run.run()` |
| **null-ls.nvim** | `:NullLsInfo` shows attached sources |

## Alacritty config

The `alacritty` directory contains `alacritty.toml` with my terminal
preferences.  It applies the
[Tokyo Night](https://github.com/folke/tokyonight.nvim) colour scheme and sets the
font size to `16` with ligatures enabled.  Copy or symlink the file to
`~/.config/alacritty/alacritty.toml` to use it.

### Keyboard shortcuts

| Shortcut | Action |
| -------- | ------ |
| `Ctrl+Shift+C` | Copy selection |
| `Ctrl+Shift+V` | Paste clipboard |
| `Ctrl+Shift+F` | Search scrollback |
| `Ctrl+Shift+L` | Clear scrollback |
| `Ctrl+Shift+R` | Reload configuration |
| `Ctrl+Shift++` | Increase font size |
| `Ctrl+-` | Decrease font size |
| `Ctrl+0` | Reset font size |
| `Ctrl+Shift+N` | New window |
| `Ctrl+Shift+W` | Close window |
| `Ctrl+Shift+Space` | Enter select mode |
| `F11` | Toggle fullscreen |
