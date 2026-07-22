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
  local file="$1" expected_servers="$2" expected_count="$3" expected_secrets="$4"
  [[ "$(grep -Ec '^\[mcp_servers\.[^]]+\]$' "$file")" -eq "$expected_count" ]] ||
    fail "$file does not contain exactly $expected_count Codex MCP entries"
  assert_contains "$file" '[mcp_servers.codegraph]'
  assert_contains "$file" '[mcp_servers.MCP_DOCKER]'
  assert_contains "$file" 'command = "docker"'
  assert_contains "$file" '"--config",'
  assert_contains "$file" 'codex-managed-config.yaml'
  assert_contains "$file" "$expected_secrets"
  assert_contains "$file" "\"--servers\", \"$expected_servers\""
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
assert_contains "$test_root/work.toml" '"--catalog", "docker-official.json"'
assert_contains "$test_root/work.toml" 'context7,notion,playwright,atlassian'
assert_contains "$test_root/work.toml" '[plugins."ponytail@ponytail"]'

CODEX_JIRA_URL="https://example.atlassian.net" \
CODEX_JIRA_USERNAME="name@example.com" \
  "$manager" apply
[[ -f "$CODEX_HOME/config.toml" ]] || fail "apply did not create config.toml"
[[ -f "$CODEX_HOME/AGENTS.md" ]] || fail "apply did not create AGENTS.md"
assert_contains "$CODEX_HOME/AGENTS.md" 'Use the installed `caveman` skill at full intensity by default'
[[ ! -e "$HOME/.config/codex/docker-mcp.env" ]] ||
  fail "macOS apply created a file-backed Docker MCP secret store"
[[ ! -d "$CODEX_HOME/plugins/cache/openai-curated-remote/linear" ]] ||
  fail "apply did not purge the Linear marketplace cache"
[[ ! -d "$CODEX_HOME/.tmp/plugins/plugins/obsidian" ]] ||
  fail "apply did not purge the Obsidian marketplace cache"
assert_contains "$HOME/.docker/mcp/codex-managed-config.yaml" '  jira:'

clean_work_home="$test_root/clean-work-home"
mkdir -p "$clean_work_home"
HOME="$clean_work_home" CODEX_HOME="$test_root/clean-work-codex" \
  CODEX_MANAGED_MACHINE="macos-work-laptop" "$manager" apply >/dev/null
[[ -f "$test_root/clean-work-codex/config.toml" ]] ||
  fail "clean work apply did not install config.toml"
assert_contains "$clean_work_home/.docker/mcp/codex-managed-config.yaml" '{}'

in_situ_home="$test_root/in-situ-home"
mkdir -p "$in_situ_home/.docker/mcp"
printf 'existing: true\n' > "$in_situ_home/.docker/mcp/codex-managed-config.yaml"
HOME="$in_situ_home" CODEX_HOME="$test_root/in-situ-codex" \
  CODEX_MANAGED_MACHINE="macos-work-laptop" "$manager" apply >/dev/null
assert_contains "$in_situ_home/.docker/mcp/codex-managed-config.yaml" 'existing: true'

export CODEX_MANAGED_MACHINE="macos-personal-macmini"
"$manager" apply --dry-run > "$test_root/personal.toml"
assert_contains "$test_root/personal.toml" 'context7,notion,playwright'

for machine in omarchy-laptop ubuntu-server; do
  CODEX_MANAGED_MACHINE="$machine" "$manager" apply --dry-run > "$test_root/$machine.toml"
done

assert_root_setting "$test_root/work.toml" 'approval_policy = "on-request"'
assert_root_setting "$test_root/work.toml" 'check_for_update_on_startup = false'
assert_mcp_shape "$test_root/work.toml" 'context7,notion,playwright,atlassian' 2 '"--secrets", "docker-desktop"'
assert_root_setting "$test_root/personal.toml" 'sandbox_mode = "workspace-write"'
assert_mcp_shape "$test_root/personal.toml" 'context7,notion,playwright' 2 '"--secrets", "docker-desktop"'
for personal_config in "$test_root/omarchy-laptop.toml"; do
  assert_root_setting "$personal_config" 'sandbox_mode = "workspace-write"'
  assert_mcp_shape "$personal_config" 'context7,notion,playwright' 2 'docker-mcp.env'
done
assert_root_setting "$test_root/ubuntu-server.toml" 'sandbox_mode = "workspace-write"'
assert_contains "$test_root/ubuntu-server.toml" '[projects."/home/gareth/src/dotfiles"]'
assert_mcp_shape "$test_root/ubuntu-server.toml" 'context7,notion,playwright' 3 'docker-mcp.env'
assert_contains "$test_root/ubuntu-server.toml" '[mcp_servers.penpot]'
assert_contains "$test_root/ubuntu-server.toml" 'url = "http://127.0.0.1:4401/mcp"'

penpot_service="$repo_root/docker/penpot-mcp"
[[ -f "$penpot_service/compose.yaml" ]] || fail "Penpot MCP Compose definition is missing"
[[ -f "$penpot_service/Dockerfile" ]] || fail "Penpot MCP Dockerfile is missing"
[[ -f "$penpot_service/.env" ]] || fail "Penpot MCP version file is missing"
docker compose -f "$penpot_service/compose.yaml" config > "$test_root/penpot-compose.yaml"
assert_contains "$test_root/penpot-compose.yaml" 'PENPOT_MCP_SERVER_HOST: 0.0.0.0'
assert_contains "$test_root/penpot-compose.yaml" 'PENPOT_MCP_PLUGIN_SERVER_HOST: 0.0.0.0'
assert_contains "$test_root/penpot-compose.yaml" 'WS_URI: ws://nuc:4402'
assert_contains "$test_root/penpot-compose.yaml" 'PENPOT_MCP_PLUGIN_ALLOWED_HOSTS: nuc'
assert_contains "$penpot_service/Dockerfile" 'patch-plugin-config.mjs'
assert_contains "$test_root/penpot-compose.yaml" 'published: "4400"'
assert_contains "$test_root/penpot-compose.yaml" 'published: "4401"'
assert_contains "$test_root/penpot-compose.yaml" 'published: "4402"'
assert_contains "$penpot_service/Dockerfile" 'ARG PENPOT_MCP_VERSION'
assert_contains "$penpot_service/.env" 'PENPOT_MCP_VERSION=2.15.4'

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

export CODEX_MANAGED_MACHINE="ubuntu-server"
mkdir -p "$CODEX_HOME/skills/ui-ux-pro-max" "$HOME/.agents/skills/impeccable"
touch "$CODEX_HOME/skills/ui-ux-pro-max/SKILL.md" "$HOME/.agents/skills/impeccable/SKILL.md"
"$manager" update --dry-run > "$test_root/update.txt"
"$manager" install --dry-run > "$test_root/install-command.txt"
assert_contains "$test_root/install-command.txt" 'would remove undeclared Codex plugins'
assert_contains "$test_root/update.txt" 'install @openai/codex@latest only when outdated'
assert_contains "$test_root/update.txt" 'latest tagged docker/mcp-gateway release'
assert_contains "$test_root/update.txt" "refresh Docker's curated MCP catalogue"
assert_contains "$test_root/update.txt" 'would remove all global Codex skills before installing the declared set'
assert_contains "$test_root/update.txt" 'would remove undeclared Codex plugins'
assert_contains "$test_root/update.txt" 'would remove undeclared Codex plugin marketplaces'
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
assert_contains "$test_root/update.txt" 'docker compose'
assert_contains "$test_root/update.txt" 'penpot-mcp'
assert_contains "$test_root/update.txt" 'PENPOT_MCP_VERSION=stable'
assert_contains "$zsh_config" 'CODEX_MANAGED_MACHINE="$managed_machine" codex-sync update'
assert_contains "$zsh_config" 'CODEX_MANAGED_MACHINE="$managed_machine" codex-sync apply'
assert_contains "$zsh_config" 'npm view "$package" version --silent'
assert_contains "$zsh_config" 'npm install -g --loglevel=error "${package}@latest"'
assert_contains "$zsh_config" 'last-successful-update'
assert_contains "$zsh_config" 'command codex --yolo "$@"'
assert_contains "$repo_root/install.sh" 'codex/managed/codex-sync" update'
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

if rg -ni '(obsidian|linear|context7[.]api_key|CONTEXT7_API_KEY)' \
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
if [ "${1:-}" = view ]; then
  printf '%s\n' "$MOCK_CODEX_VERSION"
else
  printf '%s\n' "npm $*" >> "$MOCK_LOG"
fi
EOF
cat > "$mock_bin/npx" <<'EOF'
#!/bin/sh
printf '%s\n' "npx $*" >> "$MOCK_LOG"
EOF
cat > "$mock_bin/docker" <<'EOF'
#!/bin/sh
[ "${1:-} ${2:-}" = 'mcp version' ]
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
assert_contains "$mock_log" "npx skills remove --skill * -g -a codex -y"
assert_contains "$mock_log" 'plugin remove stale@old'
assert_contains "$mock_log" 'plugin marketplace remove old'
if grep -Fq 'plugin remove ponytail@ponytail' "$mock_log"; then
  fail "dependency reset removed a declared plugin"
fi

echo "Codex managed configuration tests passed."
