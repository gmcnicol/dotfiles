# Neovim Dotfiles

This is a lean editor setup for Java/Maven/Spring basics, TypeScript, SQL, and
agent-assisted work. tmux and zsh stay responsible for shell/session workflow.

## Requirements

- Neovim 0.9.5 or newer
- `git`
- `ripgrep`
- Node/npm
- JDK and Maven, or project-local `./mvnw`
- Optional: `fzf`, SDKMAN, and project-specific formatters/linters

Run `:Lazy sync` to install plugins, then `:Mason` to inspect external tooling.
Mason is configured to install the editor-side language tools.

## Navigation

| Key | Action |
| --- | ------ |
| `<leader>pv` | Open netrw |
| `<leader>pf` | Find files from project root |
| `<leader>pg` | Find Git files from project root |
| `<leader>ps` | Search prompted string from project root |
| `<leader>pws` | Search word under cursor from project root |
| `<leader>a` | Add file to Harpoon |
| `<C-e>` | Open Harpoon menu |
| `<leader>h1` ... `<leader>h9` | Jump to Harpoon slot |
| `<C-h/j/k/l>` | Move between splits/tmux panes |
| `<C-S-h/j/k/l>` | Resize splits |

## LSP And Editing

| Key | Action |
| --- | ------ |
| `gd` / `gD` | Definition / declaration |
| `gi` / `gr` | Implementation / references |
| `K` | Hover docs |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>e` | Diagnostic float |
| `[d` / `]d` | Previous / next diagnostic |
| `<leader>f` | Format buffer manually |
| `<C-n>` / `<C-p>` | Completion next / previous |
| `<C-Space>` | Trigger completion |
| `<CR>` | Confirm completion |
| `<C-e>` | Abort completion, outside Harpoon menu contexts |

Diagnostics are quiet by default: signs and underlines are shown, virtual text is
off.

## Java And Maven

Java uses `nvim-jdtls` directly. JDTLS workspaces live under:

```text
~/.local/share/nvim/jdtls-workspaces/
```

Maven commands run from the project root and prefer `./mvnw` when available.

| Key/command | Action |
| ----------- | ------ |
| `<leader>jo` | Organize imports |
| `<leader>jt` | Run nearest Java test through JDTLS |
| `<leader>jT` | Run Java test class through JDTLS |
| `<leader>jd` | Debug nearest Java test through JDTLS/DAP |
| `<leader>jr` | Refresh main-class configs and continue DAP |
| `<leader>ju` | `:JdtUpdateConfig` |
| `<leader>mc` | `mvn compile` |
| `<leader>mt` | `mvn test` |
| `<leader>mp` | `mvn package` |
| `<leader>mb` | `mvn spring-boot:run` |
| `<leader>mR` | Prompt for a Maven goal |
| `:Maven <goal>` | Run an arbitrary Maven goal |

Spring Boot support starts with JDTLS, Maven import, YAML/properties editing,
and `spring-boot:run`. Spring Boot language-server tooling is intentionally not
enabled yet.

## Tasks And Debugging

| Key/command | Action |
| ----------- | ------ |
| `<leader>or` | `:OverseerRun` |
| `<leader>ot` | Toggle Overseer task list |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Continue debugging |
| `<leader>do` / `<leader>di` / `<leader>dO` | Step over / into / out |
| `<leader>du` | Toggle DAP UI |

DAP UI opens when a debug session starts and closes when it exits.

## Codex

Codex integration is terminal-command based and uses the existing zsh/Codex
workflow.

| Key | Action |
| --- | ------ |
| `<leader>xx` | Open `cx` in a terminal split at project root |
| `<leader>xr` | Open `codex resume` |
| `<leader>xa` | Prompt for a one-shot Codex question |
