# Developer Experience Cheat Sheet

This repository provides Neovim-centered tooling for development. The notes below highlight the essentials for quickly getting productive.

## Getting Started
- Install [Neovim](https://neovim.io/) 0.9 or later and ensure [`ripgrep`](https://github.com/BurntSushi/ripgrep) is available.
- Place these dotfiles under `~/.config` so Neovim, tmux and other tools can locate their configuration.

## Plugin and LSP Management
- `:Lazy` – open the plugin manager; `:Lazy sync` updates plugins.
- `:Mason` – install LSP servers, formatters and debuggers.
- `:LspInfo` – view active language servers for the current buffer.

## LSP Keymaps
- `gd` / `gD` – go to definition / declaration.
- `gi` / `gr` – go to implementation / references.
- `K` – hover documentation.
- `<leader>rn` – rename symbol.
- `<leader>ca` – code actions.
- `[d` / `]d` – previous / next diagnostic message.
- `<C-S-f>` – format the current buffer through the active LSP or formatter.

## Completion (Intellisense)
- `<C-n>` / `<C-p>` – navigate the completion menu.
- `<CR>` – confirm the selected entry.
- `<C-e>` – abort completion.

## Formatting Helpers
- `<C-S-f>` – format the file using available formatters.
- `:NullLsInfo` – inspect registered linters and formatters from `null-ls`.

## File Search and Navigation
- `<leader>pf` – search files in the project.
- `<leader>pg` – search files tracked by Git.
- `<leader>ps` – live grep through the project.
- `<leader>pws` – search for the word under the cursor.

With these commands you can open projects, navigate code, get completions and format files – the basics for day‑to‑day development.
