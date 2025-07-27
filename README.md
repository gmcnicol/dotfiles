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


## Karabiner home row cheatsheet

Caps Lock is remapped to `Esc`. Hold the keys below for over 200ms to send the modifier while tapping types the key normally. Holding a key after tapping keeps the modifier active instead of repeating the letter. The modifier only stays active while its key is pressed.

| Key | Held modifier |
| --- | ------------- |
| `a`/`;` | Command (right for `;`) |
| `s`/`l` | Option (right for `l`) |
| `d`/`k` | Shift (right for `k`) |
| `f`/`j` | Control (right for `j`) |
To use these rules, copy or symlink `karabiner/karabiner.json` to `~/.config/karabiner/assets/complex_modifications/` and enable "Home row modifiers" in Karabiner-Elements.

## WezTerm config

The `wezterm` directory contains `wezterm.lua` mirroring the Alacritty theme and font size.
Copy or symlink the file to `~/.config/wezterm/wezterm.lua` to use it.
It also maps `Ctrl+Shift+Space` to enter a Vim-style copy mode for selecting and yanking from the scrollback.

Padding values must include a unit such as `px` or `cell`. Using cell units
(for example `2cell`) avoids Wayland errors about the buffer size needing to be
a multiple of the display scale factor. Leaving
`adjust_window_size_when_changing_font_size` at its default value ensures that
font size changes keep the window dimensions valid.

If the window still fails to start on a high-DPI monitor (for example at 200%
scale), make sure you're running a recent WezTerm release (2024 or later) and
have the config in `~/.config/wezterm/wezterm.lua`. Older versions may ignore
cell units and produce the buffer_scale error regardless of padding.

### Keyboard shortcuts

| Shortcut | Action |
| -------- | ------ |
| `Ctrl+Shift+C` | Copy selection |
| `Ctrl+Shift+V` | Paste clipboard |
| `Ctrl+Shift+F` | Search scrollback |
| `Ctrl+Shift+R` | Reload configuration |
| `Ctrl+Shift++` | Increase font size |
| `Ctrl+-` | Decrease font size |
| `Ctrl+0` | Reset font size |
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+N` | New window |
| `Ctrl+Shift+W` | Close tab or window |
| `Ctrl+Shift+Space` | Enter copy mode |
| `Alt+Enter` | Toggle fullscreen |
| `Ctrl+Shift+Left/Right` | Cycle tabs |

### Pane management cheat sheet

**Neovim (smart-splits.nvim)**

| Shortcut | Action |
| -------- | ------ |
| `<C-h>`/`<C-j>`/`<C-k>`/`<C-l>` | Move focus to adjacent split |
| `<C-S-h>`/`<C-S-j>`/`<C-S-k>`/`<C-S-l>` | Resize current split |
| `:split` / `:vsplit` | Create horizontal/vertical split |

**WezTerm (tmux style)**

The leader key is `Ctrl+a`.

| Shortcut | Action |
| -------- | ------ |
| `Leader + \\` | Split pane horizontally |
| `Leader + -` | Split pane vertically |
| `Ctrl+h/j/k/l` | Move between panes |
| `Ctrl+Shift+h/j/k/l` | Resize active pane |
| `Leader + m` | Toggle pane zoom |
| `Leader + c` | New tab |
| `Leader + p` / `Leader + n` | Previous/next tab |
| `Leader + [1-9]` | Switch to tab number |
| `Leader + [` | Enter copy mode |
