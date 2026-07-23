#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manager="$repo_root/codex/managed/codex-sync"
zsh_config="$repo_root/zsh/.zshrc"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/codex-managed-test-XXXXXX")"
trap 'rm -rf -- "$test_root"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1" expected="$2"
  grep -Fq -- "$expected" "$file" || fail "$file does not contain: $expected"
}

assert_root_setting() {
  local file="$1" expected="$2"
  awk -v expected="$expected" '
    /^\[/ { exit }
    $0 == expected { found = 1 }
    END { exit !found }
  ' "$file" || fail "$file does not contain root setting: $expected"
}

assert_mcp_shape() {
  local file="$1" expected_count="$2"
  [[ "$(grep -Ec '^\[mcp_servers\.[^]]+\]$' "$file")" -eq "$expected_count" ]] ||
    fail "$file does not contain exactly $expected_count Codex MCP entries"
  assert_contains "$file" '[mcp_servers.codegraph]'
  assert_contains "$file" '[mcp_servers.MCP_DOCKER]'
  assert_contains "$file" 'command = "docker"'
  assert_contains "$file" 'args = ["mcp", "gateway", "run", "--profile", "default"]'
  if rg -q -- '--servers|--config|--secrets' "$file"; then
    fail "$file bypasses the local Docker MCP profile"
  fi
}

if rg -n 'mktemp( -d)? "[^"\n]*XXXXXX[^"\n]+"' "$manager"; then
  fail "managed sync uses mktemp templates rejected by macOS"
fi

export HOME="$test_root/home"
export CODEX_HOME="$test_root/codex-home"
mkdir -p "$HOME"

if env -u CODEX_MANAGED_MACHINE "$manager" apply --dry-run \
  > /dev/null 2> "$test_root/missing-machine.txt"; then
  fail "non-interactive apply succeeded without CODEX_MANAGED_MACHINE"
fi
assert_contains "$test_root/missing-machine.txt" \
  'CODEX_MANAGED_MACHINE is required in non-interactive use.'

export CODEX_MANAGED_MACHINE="macos-work-laptop"

mkdir -p \
  "$CODEX_HOME/plugins/cache/openai-curated-remote/linear" \
  "$CODEX_HOME/.tmp/plugins/plugins/obsidian"
touch \
  "$CODEX_HOME/plugins/cache/openai-curated-remote/linear/cache-entry" \
  "$CODEX_HOME/.tmp/plugins/plugins/obsidian/cache-entry"

"$manager" apply --dry-run > "$test_root/work.toml"
assert_contains "$test_root/work.toml" '[mcp_servers.MCP_DOCKER]'
assert_contains "$test_root/work.toml" '"--profile", "default"'
assert_contains "$test_root/work.toml" '[plugins."ponytail@ponytail"]'

mkdir -p "$HOME/.docker/mcp"
printf 'local: true\n' > "$HOME/.docker/mcp/config.yaml"
"$manager" apply
[[ -f "$CODEX_HOME/config.toml" ]] || fail "apply did not create config.toml"
[[ -f "$CODEX_HOME/AGENTS.md" ]] || fail "apply did not create AGENTS.md"
assert_contains "$CODEX_HOME/AGENTS.md" 'Use the installed `caveman` skill at full intensity by default'
[[ -d "$CODEX_HOME/plugins/cache/openai-curated-remote/linear" ]] ||
  fail "apply removed a user-owned Linear integration"
[[ -d "$CODEX_HOME/.tmp/plugins/plugins/obsidian" ]] ||
  fail "apply removed a user-owned Obsidian integration"
assert_contains "$HOME/.docker/mcp/config.yaml" 'local: true'

clean_work_home="$test_root/clean-work-home"
mkdir -p "$clean_work_home"
HOME="$clean_work_home" CODEX_HOME="$test_root/clean-work-codex" \
  CODEX_MANAGED_MACHINE="macos-work-laptop" "$manager" apply >/dev/null
[[ -f "$test_root/clean-work-codex/config.toml" ]] ||
  fail "clean work apply did not install config.toml"
[[ ! -e "$clean_work_home/.docker/mcp/codex-managed-config.yaml" ]] ||
  fail "apply created a competing Docker MCP configuration"

export CODEX_MANAGED_MACHINE="macos-personal-macmini"
"$manager" apply --dry-run > "$test_root/personal.toml"

for machine in omarchy-laptop ubuntu-server; do
  CODEX_MANAGED_MACHINE="$machine" "$manager" apply --dry-run > "$test_root/$machine.toml"
done

assert_root_setting "$test_root/work.toml" 'approval_policy = "on-request"'
assert_root_setting "$test_root/work.toml" 'check_for_update_on_startup = false'
assert_mcp_shape "$test_root/work.toml" 2
assert_root_setting "$test_root/personal.toml" 'sandbox_mode = "workspace-write"'
assert_mcp_shape "$test_root/personal.toml" 2
assert_root_setting "$test_root/omarchy-laptop.toml" 'sandbox_mode = "workspace-write"'
assert_mcp_shape "$test_root/omarchy-laptop.toml" 2
assert_root_setting "$test_root/ubuntu-server.toml" 'sandbox_mode = "workspace-write"'
assert_contains "$test_root/ubuntu-server.toml" '[projects."/home/gareth/src/dotfiles"]'
assert_mcp_shape "$test_root/ubuntu-server.toml" 2

cat > "$test_root/hooks.json" <<'EOF'
[
  {"pluginId":"ponytail@ponytail","key":"ponytail@ponytail:hooks/hooks.json:session_start:0:0","currentHash":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"},
  {"pluginId":"other@other","key":"other@other:hooks/hooks.json:session_start:0:0","currentHash":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"}
]
EOF
python3 "$repo_root/codex/managed/render-managed-hook-trust.py" \
  "$repo_root/codex/managed/dependencies.conf" "$repo_root" "$test_root/hooks.json" \
  > "$test_root/hook-trust.toml"
assert_contains "$test_root/hook-trust.toml" '[hooks.state."ponytail@ponytail:'
if rg -q 'other@other' "$test_root/hook-trust.toml"; then
  fail "managed config trusted a hook whose plugin is absent from dependencies.conf"
fi

HOOK_TRUST_SCRIPT="$repo_root/codex/managed/render-managed-hook-trust.py" python3 - <<'PY'
import importlib.util
import os
import pathlib
import subprocess
import types

path = pathlib.Path(os.environ["HOOK_TRUST_SCRIPT"])
spec = importlib.util.spec_from_file_location("hook_trust", path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

read_fd, write_fd = os.pipe()
os.write(write_fd, b'{"id":1}\n{"id":2}\n')
process = types.SimpleNamespace(stdout=os.fdopen(read_fd, encoding="utf-8"))
try:
    assert module.read_response(process, 1, timeout=0.1)["id"] == 1
    assert module.read_response(process, 2, timeout=0.1)["id"] == 2
finally:
    process.stdout.close()
    os.close(write_fd)

process = subprocess.Popen(["sleep", "2"], stdout=subprocess.PIPE, text=True)
try:
    try:
        module.read_response(process, 1, timeout=0.05)
    except TimeoutError:
        pass
    else:
        raise AssertionError("hook discovery timeout did not fire")
finally:
    process.kill()
    process.wait()
PY

export CODEX_MANAGED_MACHINE="ubuntu-server"
mkdir -p "$CODEX_HOME/skills/ui-ux-pro-max" "$HOME/.agents/skills/impeccable"
touch "$CODEX_HOME/skills/ui-ux-pro-max/SKILL.md" "$HOME/.agents/skills/impeccable/SKILL.md"
"$manager" update --dry-run > "$test_root/update.txt"
"$manager" install --dry-run > "$test_root/install-command.txt"
assert_contains "$test_root/update.txt" 'install @openai/codex@latest only when outdated'
assert_contains "$test_root/update.txt" "would use Docker Desktop's managed MCP Gateway plugin"
assert_contains "$test_root/update.txt" 'would add missing managed Docker MCP servers to profile default without removing local servers'
if grep -Fq 'would remove all global Codex skills before installing the declared set' "$test_root/update.txt"; then
  fail "dry-run still proposes deleting all global skills"
fi
if rg -q 'remove undeclared Codex plugin|purge.*integration' "$test_root/update.txt" "$manager"; then
  fail "managed update still removes user-owned Codex integrations"
fi
assert_contains "$test_root/update.txt" 'would install every current skill from mattpocock/skills except obsidian-vault'
assert_contains "$test_root/update.txt" 'npx skills add juliusbrussee/caveman -g -a codex -s caveman -y'
assert_contains "$test_root/update.txt" 'npx skills add pbakaus/impeccable -g -a codex -s impeccable -y'
assert_contains "$test_root/update.txt" 'npx skills add emilkowalski/skills -g -a codex -s animation-vocabulary emil-design-eng find-animation-opportunities improve-animations review-animations -y'
assert_contains "$test_root/update.txt" 'npx skills add vercel-labs/agent-skills -g -a codex -s vercel-react-best-practices -y'
assert_contains "$test_root/update.txt" 'npx skills add leonxlnx/taste-skill -g -a codex -s design-taste-frontend -y'
assert_contains "$test_root/update.txt" 'would remove legacy Codex skill install: ui-ux-pro-max'
if grep -Fq -- 'npx skills add nextlevelbuilder/ui-ux-pro-max-skill' "$test_root/update.txt"; then
  fail "updater still installs ui-ux-pro-max"
fi
assert_contains "$test_root/update.txt" 'npm install -g @colbymchenry/codegraph'
assert_contains "$test_root/update.txt" 'codex plugin marketplace upgrade ponytail'
assert_contains "$test_root/update.txt" 'codex plugin add github@openai-curated'
assert_contains "$zsh_config" 'CODEX_MANAGED_MACHINE="$managed_machine" codex-sync update'
assert_contains "$zsh_config" 'CODEX_MANAGED_MACHINE="$managed_machine" codex-sync apply'
assert_contains "$manager" 'npm view @openai/codex version --silent'
assert_contains "$zsh_config" 'npm install -g --loglevel=error "${package}@latest"'
assert_contains "$zsh_config" 'last-update-attempt'
assert_contains "$zsh_config" 'command codex --yolo "$@"'
assert_contains "$repo_root/install.sh" 'codex/managed/codex-sync" update'
assert_contains "$repo_root/install.sh" 'touch "$codex_sync_state_dir/last-update-attempt"'
if rg -q 'Skipping unmanaged Codex' "$repo_root/install.sh"; then
  fail "installer still preserves unmanaged Codex configuration"
fi
if rg -q 'codex update|dangerously-bypass-hook-trust' "$manager" "$zsh_config"; then
  fail "managed launcher still uses Codex self-update or blanket hook trust"
fi
if rg -q 'missing: work Jira configuration|gateway run --dry-run' "$manager"; then
  fail "doctor still validates user-owned MCP runtime settings"
fi
if grep -Fq -- '-quit' "$zsh_config"; then
  fail "cx uses a GNU-only find option"
fi

python3 "$repo_root/codex/managed/reconcile-skill-lock.py" \
  "$repo_root/tests/fixtures/skill-lock.json" \
  mattpocock/skills current-skill > "$test_root/stale-skills.txt"
assert_contains "$test_root/stale-skills.txt" 'obsidian-vault'
assert_contains "$test_root/stale-skills.txt" 'removed-upstream'
if rg -q 'current-skill|other-source-skill' "$test_root/stale-skills.txt"; then
  fail "skill reconciliation selected a current or differently owned skill"
fi

if CODEX_MANAGED_MACHINE="unknown-machine" "$manager" apply --dry-run >/dev/null 2>&1; then
  fail "unknown machine was accepted"
fi

if rg -n 'ctx7sk-|API_KEY[[:space:]]*=[[:space:]]*"[^$]' "$repo_root/codex/managed"; then
  fail "managed configuration contains a literal API key"
fi

if rg -ni '(obsidian|linear)' \
  "$repo_root/codex/managed" --glob '!README.md' --glob '!dependencies.conf' --glob '!codex-sync'; then
  fail "managed configuration contains a removed integration or Context7 secret"
fi

install_home="$test_root/install-home"
mock_bin="$test_root/mock-bin"
mock_log="$test_root/mock.log"
real_codex="$(command -v codex)"
mkdir -p "$install_home/.codex" "$install_home/.config/tmux/plugins/tpm" "$mock_bin"
cat > "$install_home/.codex/config.toml" <<'EOF'
[mcp_servers.unwanted]
command = "old"
EOF
cat > "$mock_bin/codex" <<'EOF'
#!/bin/sh
if [ "${1:-}" = plugin ]; then
  case "${2:-}" in
    list) printf '%s\n' \
      'stale@old  installed, enabled  1.0  stale' \
      'ponytail@ponytail  installed, enabled  4.8.4  managed' ;;
    marketplace)
      if [ "${3:-}" = list ]; then
        printf '%s\n' 'MARKETPLACE ROOT' 'old /tmp/old' 'openai-curated /tmp/openai'
      else
        printf '%s\n' "$*" >> "$MOCK_LOG"
      fi
      ;;
    *) printf '%s\n' "$*" >> "$MOCK_LOG" ;;
  esac
  exit 0
fi
exec "$REAL_CODEX" "$@"
EOF
cat > "$mock_bin/npm" <<'EOF'
#!/bin/sh
if [ "${1:-} ${2:-}" = 'list -g' ]; then
  printf '{"dependencies":{"@colbymchenry/codegraph":{"version":"%s"}}}\n' "$MOCK_CODEX_VERSION"
elif [ "${1:-}" = view ]; then
  printf '%s\n' "$MOCK_CODEX_VERSION"
else
  printf '%s\n' "npm $*" >> "$MOCK_LOG"
fi
EOF
cat > "$mock_bin/npx" <<'EOF'
#!/bin/sh
printf '%s\n' "npx $*" >> "$MOCK_LOG"
case "$*" in
  'skills list --global --json')
    printf '%s\n' '[{"name":"impeccable","source":"pbakaus/impeccable"}]'
    ;;
  'skills add mattpocock/skills '*) cat >/dev/null ;;
esac
EOF
cat > "$mock_bin/docker" <<'EOF'
#!/bin/sh
printf '%s\n' "docker $*" >> "$MOCK_LOG"
case "$*" in
  'mcp version') exit 0 ;;
  'mcp profile list')
    printf '%s\n' 'ID Name' '---- ----' 'default Default Profile'
    ;;
  'mcp profile server ls --filter profile=default')
    printf '%s\n' \
      'PROFILE | TYPE | IDENTIFIER' \
      '--------|------|-----------' \
      'default | image | playwright' \
      'default | image | local-extra'
    ;;
esac
EOF
cat > "$mock_bin/uname" <<'EOF'
#!/bin/sh
printf '%s\n' Darwin
EOF
chmod +x "$mock_bin"/*

HOME="$install_home" CODEX_HOME="$install_home/.codex" \
  PATH="$mock_bin:$PATH" CODEX_MANAGED_MACHINE=macos-personal-macmini \
  REAL_CODEX="$real_codex" MOCK_LOG="$mock_log" \
  MOCK_CODEX_VERSION="$(codex --version | awk '{print $NF}')" \
  "$repo_root/install.sh" --headless > "$test_root/install.txt"
if rg -q '^\[mcp_servers\.unwanted\]$' "$install_home/.codex/config.toml"; then
  fail "installer preserved an unmanaged MCP server"
fi
[[ -f "$install_home/.local/state/codex-sync/last-update-attempt" ]] ||
  fail "installer did not record its completed update"
assert_contains "$mock_log" 'npx skills update impeccable -g -y'
if grep -Fq 'npx skills add pbakaus/impeccable' "$mock_log"; then
  fail "dependency update reinstalled an existing skill"
fi
if grep -Fq 'npm install -g @colbymchenry/codegraph' "$mock_log"; then
  fail "dependency update reinstalled a current npm package"
fi
if grep -Fq 'plugin add ponytail@ponytail' "$mock_log"; then
  fail "dependency update reinstalled an existing plugin"
fi
if grep -Fq 'npx skills remove --skill * -g -a codex -y' "$mock_log"; then
  fail "dependency update deletes all skills before fallible installs"
fi
if rg -q 'plugin remove|plugin marketplace remove' "$mock_log"; then
  fail "dependency update removed user-owned Codex plugins"
fi
if grep -Fq 'catalog://mcp/docker-mcp-catalog/playwright' "$mock_log"; then
  fail "Docker profile reconciliation replaced an existing managed server"
fi

install_codex_log="$test_root/install-codex.log"
INSTALL_CODEX_LOG="$install_codex_log" MANAGER="$manager" bash -c '
  set -euo pipefail
  PATH=/usr/bin:/bin
  dry_run=0
  eval "$(sed -n "/^update_codex() {/,/^}/p" "$MANAGER")"
  npm() { printf "%s\n" "$*" >> "$INSTALL_CODEX_LOG"; }
  update_codex
'
assert_contains "$install_codex_log" 'install -g --loglevel=error @openai/codex@latest'

echo "Codex managed configuration tests passed."
