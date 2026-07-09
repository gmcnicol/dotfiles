# Zsh Dotfiles

This bundle consolidates the reusable customizations from the synced machine configs while leaving Oh My Zsh itself out of the repo.

## Files

- `.zshrc`: shared interactive personalisation to source from an existing Oh My Zsh `~/.zshrc`.
- `.zshenv`: fast shell environment split into a tiny always-on layer and a background-shell toolchain layer.
- `~/.zshrc.local`: optional private file for machine-specific exports, secrets, and work credentials.

## Interactive vs Background Shells

The split is intentional:

- Interactive shells read `.zshenv`, then the machine's existing Oh My Zsh `~/.zshrc`, which should source this repo's `.zshrc` after `source "$ZSH/oh-my-zsh.sh"`. They get prompt setup, aliases, key bindings, clipboard helpers, and deferred CLI integration.
- Background shells such as `zsh -c`, Codex command runners, and similar automation read `.zshenv` only. They get PATH access to tools like `fzf`, Node, Java, Ruby, Python, Fly, LM Studio, and JetBrains scripts without loading Oh My Zsh, nvm, SDKMAN, completions, prompt hooks, or network checks.

This preserves the MacBook pattern: automation has the toolchain it needs, while full shell customization stays interactive-only.

The base PATH layer is shared by interactive and background shells and includes
local user binaries, fzf, Fly.io CLI, Homebrew, and common system paths.

## Oh My Zsh Ownership

Oh My Zsh setup stays in each machine's real `~/.zshrc`: `ZSH`, `ZSH_THEME`, `plugins`, completion paths, and `source "$ZSH/oh-my-zsh.sh"` all belong there.

This repo's `.zshrc` is loaded after Oh My Zsh and only contains personal behaviour: prompt setup, aliases, key bindings, clipboard helpers, small shell functions, and deferred CLI integration.

Useful terminal-oriented plugins to configure in the real `~/.zshrc` where wanted:

- `fzf`
- `zoxide`
- `thefuck`
- `nvm`

The `fzf` command itself is still made available from `.zshenv` when installed in a normal PATH location such as `~/.fzf/bin`; only its key bindings and completion setup are TTY-gated.

### macOS nvm bootstrap

On macOS machines using Homebrew `nvm`, the real `~/.zshrc` must load nvm
before sourcing this repo's `.zshrc`:

```zsh
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]] && source "/opt/homebrew/opt/nvm/nvm.sh"
[[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]] && source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

source "$HOME/.config/zsh/.zshrc"
```

The shared `.zshrc` intentionally only runs `nvm use default` when the `nvm`
function already exists. This keeps the repo config portable, but it means tools
installed under an nvm-managed Node, such as `codegraph`, will disappear from
fresh login shells and MCP startup environments if the machine bootstrap omits
the Homebrew nvm source lines.

## Machine Prerequisites

For consistent behaviour on every machine, install these everywhere:

- `zsh`
- `tmux`
- Oh My Zsh in `~/.oh-my-zsh`
- `git`
- Node/npm, preferably managed by `nvm`
- `fzf`
- `zoxide`
- `atuin`
- `thefuck`
- Docker with `docker compose`
- OpenAI Codex CLI, or just `npm` so the `cx` function can install/update `@openai/codex`

These are used when present, but the config degrades cleanly without them:

- `ngrok`
- `tailscale`
- `bat` on macOS, `batcat` on Debian/Ubuntu
- `aws` CLI, for `cauth`
- `claude` CLI, for `cmau`
- `rbenv`, for Ruby shims
- Go, for `~/go/bin`
- SDKMAN and a current Java install
- Fly.io CLI, in `~/.fly/bin`
- LM Studio CLI, in `~/.lmstudio/bin`
- JetBrains Toolbox scripts

Linux machines should also install one clipboard backend so `pbcopy`/`pbpaste` work:

- `wl-clipboard`, preferred on Wayland
- `xclip`, fallback for X11
- `xsel`, fallback for X11

Useful Oh My Zsh custom plugins to install where wanted:

- `zsh-completions`
- `zoxide`, if using the OMZ plugin rather than only `zoxide init`
- `fzf`, if using the OMZ plugin rather than only `fzf --zsh`
- `thefuck`

## Copy-Paste Installs

Run the relevant block from this repo folder. Each block installs the usual tools, preserves the machine's real Oh My Zsh `~/.zshrc`, links this repo's `.zshenv`, creates `~/.zshrc.local`, and appends the import for this repo's personalisation.

### macOS: Homebrew

```sh
set -eu

DOTFILES_ZSH_DIR="${DOTFILES_ZSH_DIR:-$PWD}"

brew install zsh tmux git nvm fzf zoxide atuin thefuck bat awscli rbenv go sdkman-cli flyctl ngrok
brew install --cask docker tailscale lm-studio jetbrains-toolbox

RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

mkdir -p "$HOME/.nvm"
export NVM_DIR="$HOME/.nvm"
. "$(brew --prefix nvm)/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

npm install -g @openai/codex @anthropic-ai/claude-code

ln -sf "$DOTFILES_ZSH_DIR/.zshenv" "$HOME/.zshenv"
touch "$HOME/.zshrc.local"
chmod 600 "$HOME/.zshrc.local"

SOURCE_LINE="source \"$DOTFILES_ZSH_DIR/.zshrc\""
touch "$HOME/.zshrc"
grep -Fqx "$SOURCE_LINE" "$HOME/.zshrc" || {
  printf '\n# Personal zsh customisations\n%s\n' "$SOURCE_LINE" >> "$HOME/.zshrc"
}
```

### Ubuntu/Debian: apt

```sh
set -eu

DOTFILES_ZSH_DIR="${DOTFILES_ZSH_DIR:-$PWD}"

sudo apt update
sudo apt install -y \
  zsh tmux git curl build-essential ca-certificates gnupg \
  nodejs npm fzf zoxide thefuck \
  docker.io docker-compose-plugin \
  wl-clipboard xclip xsel \
  bat awscli rbenv golang-go pipx

RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
curl -s "https://get.sdkman.io" | bash
npm install -g @openai/codex @anthropic-ai/claude-code

sudo usermod -aG docker "$USER"

ln -sf "$DOTFILES_ZSH_DIR/.zshenv" "$HOME/.zshenv"
touch "$HOME/.zshrc.local"
chmod 600 "$HOME/.zshrc.local"

SOURCE_LINE="source \"$DOTFILES_ZSH_DIR/.zshrc\""
touch "$HOME/.zshrc"
grep -Fqx "$SOURCE_LINE" "$HOME/.zshrc" || {
  printf '\n# Personal zsh customisations\n%s\n' "$SOURCE_LINE" >> "$HOME/.zshrc"
}
```

Debian/Ubuntu call `bat` as `batcat`; the shared config aliases `bat` to `batcat` when needed. This block installs `wl-clipboard`, `xclip`, and `xsel`, so the shared config can provide macOS-style `pbcopy`/`pbpaste` on Wayland or X11. Log out and back in after the Ubuntu/Debian block so Docker group membership takes effect.

### Omarchy/Arch: pacman

```sh
set -eu

DOTFILES_ZSH_DIR="${DOTFILES_ZSH_DIR:-$PWD}"

sudo pacman -Syu
sudo pacman -S --needed \
  zsh tmux git base-devel curl \
  nodejs npm fzf zoxide atuin thefuck \
  docker docker-compose \
  wl-clipboard xclip xsel \
  bat aws-cli rbenv go jdk-openjdk \
  tailscale

RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
sudo systemctl enable --now tailscaled

if command -v paru >/dev/null 2>&1; then
  paru -S --needed ngrok-bin lmstudio
fi

npm install -g @openai/codex @anthropic-ai/claude-code

ln -sf "$DOTFILES_ZSH_DIR/.zshenv" "$HOME/.zshenv"
touch "$HOME/.zshrc.local"
chmod 600 "$HOME/.zshrc.local"

SOURCE_LINE="source \"$DOTFILES_ZSH_DIR/.zshrc\""
touch "$HOME/.zshrc"
grep -Fqx "$SOURCE_LINE" "$HOME/.zshrc" || {
  printf '\n# Personal zsh customisations\n%s\n' "$SOURCE_LINE" >> "$HOME/.zshrc"
}
```

Omarchy can also install packages from the menu with `Super + Alt + Space`, then `Install > Package`. This block installs `wl-clipboard`, `xclip`, and `xsel`, so the shared config can provide macOS-style `pbcopy`/`pbpaste` on Wayland or X11. Log out and back in after this block so Docker group membership takes effect.

## Local Secrets

Do not commit API keys or generated tokens. Put private values in `~/.zshrc.local`, for example:

```zsh
export CODEARTIFACT_DOMAIN="example"
export CODEARTIFACT_DOMAIN_OWNER="123456789012"
export CODEARTIFACT_REGION="eu-west-2"
export OPENAI_API_KEY="..."
export ANTHROPIC_API_KEY="..."
```
