# Shared interactive zsh personalisation.
# Background/non-interactive shell setup lives in ~/.zshenv.
# Machine-specific exports and secrets belong in ~/.zshrc.local.
#
# Source this file from an existing Oh My Zsh ~/.zshrc after:
#   source "$ZSH/oh-my-zsh.sh"

[[ -o interactive ]] || return

HOMEBREW_NO_ENV_HINTS=true
export EDITOR='nvim'

typeset -U path PATH fpath FPATH

is_codex_shell=false
if [[ -n ${CODEX_THREAD_ID:-} || -n ${CODEX_INTERNAL_ORIGINATOR_OVERRIDE:-} ]]; then
  is_codex_shell=true
fi
has_tty_ui=false
if [[ -t 0 && -t 1 ]]; then
  has_tty_ui=true
fi

# Ghostty's terminfo is not installed on many remote hosts.
if [[ "$TERM" == xterm-ghostty ]] && ! infocmp xterm-ghostty >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

# Reuse nvm if the parent ~/.zshrc or Oh My Zsh plugin made it available.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
command -v nvm >/dev/null 2>&1 && nvm use default >/dev/null 2>&1

if [[ "$is_codex_shell" == true ]]; then
  PROMPT='%F{39}%1~%f %# '
  RPROMPT=''
else
  setopt prompt_subst
  autoload -Uz add-zsh-hook vcs_info
  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:git*:*' formats '%b'

  _short_path() {
    local p="$PWD" base parent rel
    if [[ $p == $HOME || $p == "$HOME"/ ]]; then
      print -r -- '~'
      return
    fi
    if [[ $p == $HOME/* ]]; then
      rel="${p#$HOME/}"
      base="${rel##*/}"
      parent="${rel%/*}"
      parent="${parent##*/}"
      [[ -z $parent ]] && print -r -- "~/$base" || print -r -- "~/$parent/$base"
      return
    fi
    base="${p##*/}"
    parent="${p%/*}"
    parent="${parent##*/}"
    [[ -z $parent || $parent == '/' ]] && print -r -- "/$base" || print -r -- "$parent/$base"
  }

  _custom_prompt_precmd() {
    vcs_info
    local branch="$vcs_info_msg_0_" sp git_ind="" header sep
    sp=$(_short_path)

    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      local ab ahead behind
      ab=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null || true)
      if [[ -n $ab ]]; then
        behind=${ab%%[[:space:]]*}
        ahead=${ab##*[[:space:]]}
        [[ ${ahead:-0} -gt 0 ]] && git_ind+=$' ↑'${ahead}
        [[ ${behind:-0} -gt 0 ]] && git_ind+=$' ↓'${behind}
      fi
      if ! git diff --no-ext-diff --ignore-submodules --quiet 2>/dev/null \
        || ! git diff --no-ext-diff --ignore-submodules --cached --quiet 2>/dev/null \
        || [[ -n $(git ls-files --others --exclude-standard 2>/dev/null | sed -n '1p') ]]; then
        git_ind+=$' ✱'
      fi
    fi

    sep=$'\uE0B0'
    header="%K{229}%F{0} ${sp} %f%k"
    if [[ -n $branch ]]; then
      header+="%F{229}%K{22}${sep}%f%k%K{22}%F{254} ${branch}${git_ind:+ ${git_ind}} %f%k"
    fi
    PROMPT="$header"$'\n'"%F{218}ඞ %f"
  }
  add-zsh-hook precmd _custom_prompt_precmd

  if [[ "$has_tty_ui" == true ]]; then
    _load_fzf_zsh_integration() {
      emulate -L zsh
      local file
      local -a fallback_files

      command -v fzf >/dev/null 2>&1 || return 0

      if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
        return 0
      fi

      fallback_files=(
        "$HOME/.fzf/shell/completion.zsh"
        "$HOME/.fzf/shell/key-bindings.zsh"
        "/opt/homebrew/opt/fzf/shell/completion.zsh"
        "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
        "/usr/local/opt/fzf/shell/completion.zsh"
        "/usr/local/opt/fzf/shell/key-bindings.zsh"
        "/usr/share/doc/fzf/examples/completion.zsh"
        "/usr/share/doc/fzf/examples/key-bindings.zsh"
        "/usr/share/fzf/completion.zsh"
        "/usr/share/fzf/key-bindings.zsh"
      )

      for file in $fallback_files; do
        [[ -r "$file" ]] && source "$file"
      done
    }

    _defer_cli_init() {
      command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
      command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh)"
      command -v ngrok >/dev/null 2>&1 && eval "$(ngrok completion)"
      _load_fzf_zsh_integration
      add-zsh-hook -d preexec _defer_cli_init
    }
    add-zsh-hook preexec _defer_cli_init
  fi
fi

# macOS-compatible clipboard commands on Linux.
if ! command -v pbcopy >/dev/null 2>&1; then
  if command -v wl-copy >/dev/null 2>&1 && command -v wl-paste >/dev/null 2>&1; then
    pbcopy() { wl-copy; }
    pbpaste() { wl-paste; }
  elif command -v xclip >/dev/null 2>&1; then
    pbcopy() { xclip -selection clipboard; }
    pbpaste() { xclip -selection clipboard -o; }
  elif command -v xsel >/dev/null 2>&1; then
    pbcopy() { xsel --clipboard --input; }
    pbpaste() { xsel --clipboard --output; }
  fi
fi

_tmux_project_roots() {
  emulate -L zsh
  local -a roots

  roots=(
    "$HOME/src"
    "$HOME/work"
    "$HOME/code"
    "$HOME/dev"
    "$HOME/Developer"
    "$HOME/Sites"
    "$HOME"
  )

  if [[ -n ${TMUX_PROJECT_ROOTS:-} ]]; then
    roots=("${(@s/:/)TMUX_PROJECT_ROOTS}" $roots)
  fi

  local root
  for root in $roots; do
    [[ -d "$root" ]] && print -r -- "$root"
  done
}

_tmux_sanitize_session_name() {
  emulate -L zsh
  local name

  name=$(print -r -- "${1:-main}" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -c '[:alnum:]_-' '_' \
    | sed 's/^_*//; s/_*$//; s/__*/_/g')

  print -r -- "${name:-main}"
}

_tmux_abs_dir() {
  emulate -L zsh
  local dir="${1:-$PWD}"

  (builtin cd -q -- "$dir" && pwd -P)
}

_tmux_current_project_dir() {
  emulate -L zsh
  local git_root

  if command -v git >/dev/null 2>&1; then
    git_root=$(git rev-parse --show-toplevel 2>/dev/null) && {
      _tmux_abs_dir "$git_root"
      return
    }
  fi

  _tmux_abs_dir "$PWD"
}

_tmux_find_project_dir() {
  emulate -L zsh
  local name="$1" root candidate
  local -a candidates

  for root in $(_tmux_project_roots); do
    candidates=("$root/$name" "$root/${name:l}")
    for candidate in $candidates; do
      if [[ -d "$candidate" ]]; then
        _tmux_abs_dir "$candidate"
        return
      fi
    done
  done

  return 1
}

_tmux_project_candidates() {
  emulate -L zsh
  local root dir name

  for root in $(_tmux_project_roots); do
    for dir in "$root"/*(/N); do
      name=$(_tmux_sanitize_session_name "${dir:t}")
      print -r -- "$name"$'\t'"$dir"
    done
  done
}

_tmux_resolve_target() {
  emulate -L zsh
  local input="${1:-}" requested_dir="${2:-}" session dir name

  if [[ -n "$requested_dir" ]]; then
    dir=$(_tmux_abs_dir "$requested_dir") || return
    name="${input:-${dir:t}}"
  elif [[ -n "$input" && -d "$input" ]]; then
    dir=$(_tmux_abs_dir "$input") || return
    name="${dir:t}"
  elif [[ -n "$input" ]]; then
    name="$input"
    dir=$(_tmux_find_project_dir "$input" 2>/dev/null || _tmux_abs_dir "$PWD") || return
  else
    dir=$(_tmux_current_project_dir) || return
    [[ "$dir" == "$HOME" ]] && name="main" || name="${dir:t}"
  fi

  session=$(_tmux_sanitize_session_name "$name")
  print -r -- "$session"$'\t'"$dir"
}

t() {
  emulate -L zsh
  local target session dir

  if ! command -v tmux >/dev/null 2>&1; then
    print -u2 "t: tmux is not installed"
    return 127
  fi

  target=$(_tmux_resolve_target "$@") || return
  session="${target%%$'\t'*}"
  dir="${target#*$'\t'}"

  if [[ -n ${TMUX:-} ]]; then
    tmux has-session -t "=$session" 2>/dev/null \
      || tmux new-session -d -s "$session" -c "$dir" \
      || return
    tmux switch-client -t "=$session"
  else
    tmux new-session -A -s "$session" -c "$dir"
  fi
}

tl() {
  emulate -L zsh

  print "sessions"
  if command -v tmux >/dev/null 2>&1; then
    tmux list-sessions -F '  #{session_name}' 2>/dev/null || print "  none"
  else
    print "  tmux is not installed"
  fi

  print
  print "projects"
  _tmux_project_candidates | sort -u | while IFS=$'\t' read -r name dir; do
    printf '  %-24s %s\n' "$name" "$dir"
  done
}

tt() {
  emulate -L zsh
  local selected kind rest name dir

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 "tt: fzf is not installed; showing tl instead"
    tl
    return 1
  fi

  selected=$(
    {
      command -v tmux >/dev/null 2>&1 && tmux list-sessions -F $'session\t#{session_name}\t' 2>/dev/null
      _tmux_project_candidates | sort -u | while IFS=$'\t' read -r name dir; do
        print -r -- "project"$'\t'"$name"$'\t'"$dir"
      done
    } | fzf --prompt='tmux> ' --delimiter=$'\t' --with-nth=1,2,3
  ) || return

  kind="${selected%%$'\t'*}"
  rest="${selected#*$'\t'}"
  name="${rest%%$'\t'*}"
  dir="${rest#*$'\t'}"

  [[ "$kind" == "project" ]] && t "$name" "$dir" || t "$name"
}

_t() {
  emulate -L zsh
  local -a candidates

  command -v tmux >/dev/null 2>&1 && candidates+=("${(@f)$(tmux list-sessions -F '#{session_name}' 2>/dev/null)}")
  candidates+=("${(@f)$(_tmux_project_candidates | awk -F '\t' '{print $1}')}")
  compadd -U -a candidates
}

(( $+functions[compdef] )) && compdef _t t

# Normalize backspace/delete keys in zsh vi mode, especially over SSH.
bindkey -M viins '^?' vi-backward-delete-char
bindkey -M viins '^H' vi-backward-delete-char
bindkey -M viins "${terminfo[kdch1]:-$'\e[3~'}" delete-char
bindkey -M vicmd '^?' vi-backward-char
bindkey -M vicmd '^H' vi-backward-char
bindkey -M vicmd "${terminfo[kdch1]:-$'\e[3~'}" vi-delete-char

alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dkf="docker compose down && docker system prune -af && docker volume prune -af"
alias dcp="docker compose pull"
command -v batcat >/dev/null 2>&1 && alias bat="batcat"
command -v fuck >/dev/null 2>&1 && alias huh='fuck'
alias cmau='claude mcp add --scope user'

unalias cx 2>/dev/null
cx() {
  local package="@openai/codex"
  local sync_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/codex-sync"
  local sync_stamp="$sync_state_dir/last-successful-update"
  local sync_due=0

  if ! command -v codex >/dev/null 2>&1; then
    if ! command -v npm >/dev/null 2>&1; then
      print -u2 "cx: npm is required to install ${package}"
      return 127
    fi
    print "cx: installing ${package}@latest"
    npm install -g "${package}@latest" || return
  fi

  if ! command -v codex-sync >/dev/null 2>&1; then
    print -u2 "cx: codex-sync is required; run the dotfiles installer"
    return 127
  fi

  if [[ "${CX_SYNC_ALWAYS:-0}" == 1 || ! -f "$sync_stamp" ]]; then
    sync_due=1
  elif [[ -z "$(find "$sync_stamp" -mmin -1440 -print 2>/dev/null)" ]]; then
    sync_due=1
  fi

  if (( sync_due )); then
    print "cx: synchronising Codex configuration and dependencies"
    codex-sync update || return
    mkdir -p "$sync_state_dir" || return
    touch "$sync_stamp" || return
  else
    codex-sync apply || return
  fi

  command codex "$@"
}

refresh_codeartifact_token() {
  command -v aws >/dev/null 2>&1 || { print -u2 "aws CLI not found"; return 1; }
  : "${CODEARTIFACT_DOMAIN:?set CODEARTIFACT_DOMAIN in ~/.zshrc.local}"
  : "${CODEARTIFACT_DOMAIN_OWNER:?set CODEARTIFACT_DOMAIN_OWNER in ~/.zshrc.local}"
  : "${CODEARTIFACT_REGION:?set CODEARTIFACT_REGION in ~/.zshrc.local}"
  export CODEARTIFACT_AUTH_TOKEN="$(
    aws codeartifact get-authorization-token \
      --domain "$CODEARTIFACT_DOMAIN" \
      --domain-owner "$CODEARTIFACT_DOMAIN_OWNER" \
      --region "$CODEARTIFACT_REGION" \
      --query authorizationToken \
      --output text
  )"
  print "CodeArtifact token refreshed"
}
alias cauth='refresh_codeartifact_token'

export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
sdk() {
  export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
  if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    command sdk "$@"
  else
    print -u2 "sdk: SDKMAN not installed"
    return 1
  fi
}

[[ -r "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"
[[ -r "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
[[ -r "$HOME/.local/share/../bin/env" ]] && . "$HOME/.local/share/../bin/env"

if [[ -n ${fpath[1]:-} ]] && command -v tailscale >/dev/null 2>&1 && [[ -w "${fpath[1]}" ]]; then
  tailscale completion zsh > "${fpath[1]}/_tailscale" 2>/dev/null
fi

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
