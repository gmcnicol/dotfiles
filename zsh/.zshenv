# Shared zsh environment for every zsh process.
# Keep this fast: no prompts, completions, network calls, plugins, or tool init.

typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/.fzf/bin"
  "$HOME/bin"
  "$HOME/.fly/bin"
  /opt/homebrew/bin
  /opt/homebrew/sbin
  /usr/local/bin
  $path
)

# Interactive shells load the richer setup from ~/.zshrc.
if [[ -o interactive ]]; then
  export PATH
  return
fi

# Background shells, including Codex-style `zsh -c` commands, need toolchains on
# PATH without sourcing Oh My Zsh, nvm, SDKMAN, prompts, or completions.
path=(
  "$HOME/.rbenv/shims"
  "$HOME/.rbenv/bin"
  "$HOME/go/bin"
  $path
)

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -r "$NVM_DIR/alias/default" ]]; then
  _nvm_default="$(<"$NVM_DIR/alias/default")"
  [[ "$_nvm_default" != v* ]] && _nvm_default="v${_nvm_default}"
  [[ -d "$NVM_DIR/versions/node/${_nvm_default}/bin" ]] && path=("$NVM_DIR/versions/node/${_nvm_default}/bin" $path)
  unset _nvm_default
fi

export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
if [[ -d "$SDKMAN_DIR/candidates/java/current" ]]; then
  export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"
  path=("$JAVA_HOME/bin" $path)
fi

if [[ -d "/Library/Frameworks/Python.framework/Versions/3.10/bin" ]]; then
  path=("/Library/Frameworks/Python.framework/Versions/3.10/bin" $path)
fi

for _python_bin in "$HOME"/Library/Python/*/bin(N); do
  path=("$_python_bin" $path)
done
unset _python_bin

[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && path+=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts")
[[ -d "$HOME/.lmstudio/bin" ]] && path+=("$HOME/.lmstudio/bin")
[[ -d "$HOME/.fly/bin" ]] && path=("$HOME/.fly/bin" $path)

export PATH
