# dotfiles
Settings I want between different unix type installations.

## Install

From this repo:

```sh
./install.sh
```

The installer links AeroSpace, Neovim, tmux, and zsh into the expected config
locations, creates `~/.zshrc.local`, and installs TPM if it is missing. Ghostty
config is linked only when Ghostty is installed or `DOTFILES_INSTALL_GHOSTTY=1`
is set. Use `--headless` on servers to skip Ghostty even if it is installed. If
a real file or directory already exists where a link should go, the script
stops. Re-run with `--force` to move the existing path aside with a timestamped
`.bak` suffix.

The script is idempotent: running it again leaves existing correct links and
the zsh source line unchanged.

## AeroSpace setup

The AeroSpace config lives at `aerospace/aerospace.toml` and is symlinked to
`~/.config/aerospace/aerospace.toml`.

It mirrors the Omarchy Hyprland tiling flow: Option + arrows focus windows,
Option + Shift + arrows swap windows, Option + number switches workspaces, and
Option + Shift + number moves the focused window there. Command stays available
for normal macOS app shortcuts; use Command only in combined window-manager
bindings such as Option + Command + Shift + number for silent moves.

Reload after linking:

```sh
aerospace reload-config
```

## Ghostty setup

The Ghostty config is shared from `ghostty/config.ghostty` and should be
symlinked to `~/.config/ghostty/config.ghostty` on macOS and Omarchy.

The installer does this automatically when Ghostty is installed. On headless
machines, skip Ghostty explicitly:

```sh
./install.sh --headless
```

To force the link anyway:

```sh
DOTFILES_INSTALL_GHOSTTY=1 ./install.sh
```

Manual setup:

```sh
mkdir -p "$HOME/.config/ghostty"
ln -sf "$PWD/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
```

Ghostty reads the XDG config path on both Linux and macOS:

```text
~/.config/ghostty/config.ghostty
```

macOS can also read:

```text
~/Library/Application Support/com.mitchellh.ghostty/config.ghostty
```

If both exist, the macOS app-support config is loaded after the XDG config and
can override it. For these dotfiles, prefer the XDG path above and avoid keeping
a second macOS-specific Ghostty config unless you intentionally want local
overrides.

Reload Ghostty after linking with `Cmd-Shift-,` on macOS or `Ctrl-Shift-,` on
Linux, or restart Ghostty.

Useful bindings:

| Key | Action |
| --- | ------ |
| `Cmd-c` / `Ctrl-Shift-c` | Copy selection |
| `Cmd-v` / `Ctrl-Shift-v` | Paste clipboard |
| `Cmd-f` / `Ctrl-Shift-f` | Start Ghostty scrollback search |
| `Cmd-Shift-j` / `Ctrl-Shift-j` | Paste a temp scrollback file path |
| `Cmd-Shift-o` / `Ctrl-Shift-o` | Open scrollback in the OS text editor |
| `Cmd-Shift-,` / `Ctrl-Shift-,` | Reload Ghostty config |

For Vim-style terminal selection, use tmux copy mode: `Ctrl-Space [` then
`v` to select and `y` to yank.

## Tmux setup

The tmux config is shared from `tmux/tmux.conf` and should be symlinked to
`~/.config/tmux/tmux.conf` on every machine.

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
`git` are available. The prefix is `Ctrl-Space`.

The matching zsh helpers live in `zsh/.zshrc`:

| Command | Action |
| ------- | ------ |
| `t` | Attach/create a session for the current Git repo or `main` from `$HOME` |
| `t dotfiles` | Attach/create `dotfiles`, searching common project roots |
| `t dotfiles ~/src/dotfiles` | Attach/create `dotfiles` at an explicit directory |
| `tt` | Fuzzy-pick existing sessions and common project directories |
| `tl` | List existing sessions and common project directories |

See `tmux/README.md` for the cheat sheet.

## Neovim setup

The Neovim config is a lean language-aware editor, not a shell replacement. It
uses Catppuccin Mocha to match tmux and focuses on Java/Maven/Spring basics,
TypeScript, SQL, Telescope, Harpoon, LSP, formatting, and a small Codex doorway.

Prerequisites:

- Neovim 0.9.5 or newer for now
- `git`
- `ripgrep`
- Node/npm for TypeScript, ESLint, Prettier, and Codex
- JDK and Maven, preferably via SDKMAN/Homebrew/apt/pacman or project `mvnw`

Useful entry points:

| Key/command | Action |
| ----------- | ------ |
| `:Lazy` | Plugin manager |
| `:Mason` | LSP/DAP/tool installer |
| `<leader>pv` | netrw project browser |
| `<leader>pf` / `<leader>pg` | Find files / Git files |
| `<leader>ps` / `<leader>pws` | Search string / word |
| `<leader>a` / `<C-e>` | Harpoon add / menu |
| `<leader>mc` / `<leader>mt` / `<leader>mp` | Maven compile / test / package |
| `<leader>mb` | `mvn spring-boot:run` |
| `<leader>xx` / `<leader>xr` / `<leader>xa` | Codex open / resume / ask |

See `nvim/README.md` for the full cheat sheet.


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
| `Cmd+T` / `Ctrl+Shift+T` | New window for AeroSpace |
| `Cmd+Shift+T` | New Ghostty tab |
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
