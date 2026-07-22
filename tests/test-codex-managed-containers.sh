#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${CODEX_CONTAINER_CASE:-}" ]]; then
  test_root="$(mktemp -d /tmp/codex-container-test-XXXXXX)"
  trap 'rm -rf -- "$test_root"' EXIT
  mock_bin="$test_root/bin"
  mkdir -p "$mock_bin"
  export MOCK_LOG="$test_root/commands.log"

  cat > "$mock_bin/codex" <<'EOF'
#!/bin/sh
printf 'codex %s\n' "$*" >> "$MOCK_LOG"
case "${1:-} ${2:-}" in
  "app-server --stdio")
    while IFS= read -r line; do
      case "$line" in
        *'"id": 1'*) printf '%s\n' '{"id":1,"result":{}}' ;;
        *'"id": 2'*) printf '%s\n' '{"id":2,"result":{"data":[{"hooks":[]}]}}' ;;
      esac
    done
    ;;
  "--strict-config doctor") printf '%s\n' '{"config.toml parse": "ok"}' ;;
  "--version ") printf '%s\n' 'codex-cli 0.0.0' ;;
  "plugin list")
    printf '%s\n' 'ponytail@ponytail installed, enabled' 'github@openai-curated installed, enabled'
    ;;
  "plugin marketplace") printf '%s\n' 'MARKETPLACE ROOT' 'openai-curated builtin' 'ponytail remote' ;;
esac
EOF

  cat > "$mock_bin/docker" <<'EOF'
#!/bin/sh
printf 'docker %s\n' "$*" >> "$MOCK_LOG"
exit 0
EOF

  cat > "$mock_bin/uname" <<'EOF'
#!/bin/sh
if [ -n "${MOCK_UNAME:-}" ]; then
  printf '%s\n' "$MOCK_UNAME"
else
  /usr/bin/uname "$@"
fi
EOF

  cat > "$mock_bin/npm" <<'EOF'
#!/bin/sh
printf 'npm %s\n' "$*" >> "$MOCK_LOG"
if [ "${1:-} ${2:-} ${3:-}" = "view @openai/codex version" ]; then
  printf '%s\n' '0.0.0'
fi
EOF

  cat > "$mock_bin/npx" <<'EOF'
#!/bin/sh
printf 'npx %s\n' "$*" >> "$MOCK_LOG"
if [ "${1:-} ${2:-}" = "skills add" ]; then
  selecting=false
  for argument do
    case "$argument" in
      -s) selecting=true ;;
      -y) selecting=false ;;
      -*) ;;
      *)
        if [ "$selecting" = true ]; then
          mkdir -p "$AGENTS_HOME/skills/$argument"
          : > "$AGENTS_HOME/skills/$argument/SKILL.md"
        fi
        ;;
    esac
  done
fi
EOF

  cat > "$mock_bin/git" <<'EOF'
#!/bin/sh
printf 'git %s\n' "$*" >> "$MOCK_LOG"
if [ "${1:-}" = ls-remote ]; then
  printf '%s\n' '0000000000000000000000000000000000000000 refs/tags/v1.0.0'
  exit 0
fi
if [ "${1:-}" = clone ]; then
  source=
  destination=
  for argument do
    destination=$argument
    case "$argument" in https://github.com/*) source=$argument ;; esac
  done
  mkdir -p "$destination"
  case "$source" in
    *mattpocock/skills.git)
      mkdir -p "$destination/skills/current-skill" "$destination/skills/obsidian-vault"
      : > "$destination/skills/current-skill/SKILL.md"
      : > "$destination/skills/obsidian-vault/SKILL.md"
      ;;
  esac
fi
EOF

  cat > "$mock_bin/make" <<'EOF'
#!/bin/sh
printf 'make %s\n' "$*" >> "$MOCK_LOG"
for argument do
  case "$argument" in
    DOCKER_MCP_CLI_PLUGIN_DST=*) target=${argument#*=} ;;
  esac
done
mkdir -p "$(dirname "$target")"
printf '#!/bin/sh\nexit 0\n' > "$target"
chmod +x "$target"
EOF

  cat > "$mock_bin/curl" <<'EOF'
#!/bin/sh
printf 'curl %s\n' "$*" >> "$MOCK_LOG"
output=
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then
    shift
    output=$1
  fi
  shift
done
printf '%s\n' '{"registry":{"context7":{},"notion":{},"playwright":{},"atlassian":{}}}' > "$output"
EOF

  cat > "$mock_bin/python3" <<'EOF'
#!/bin/sh
# Python behaviour is covered by the host regression suite. Container cases
# exercise the OS shell, installer, filesystem layout, and update orchestration.
exit 0
EOF

  cat > "$mock_bin/go" <<'EOF'
#!/bin/sh
exit 0
EOF

  cat > "$mock_bin/hostname" <<'EOF'
#!/bin/sh
printf '%s\n' container-test
EOF

  cat > "$mock_bin/cmp" <<'EOF'
#!/bin/sh
# Minimal images omit diffutils. Returning different exercises safe replacement.
exit 1
EOF

  chmod +x "$mock_bin"/*
  export PATH="$mock_bin:$PATH"
  export AGENTS_HOME="$test_root/agents"

  case "$CODEX_CONTAINER_CASE" in
    ubuntu) machines=(ubuntu-server) ;;
    arch) machines=(omarchy-laptop) ;;
    macos)
      export MOCK_UNAME=Darwin
      machines=(macos-work-laptop macos-personal-macmini)
      ;;
    *)
      echo "Unknown container case: $CODEX_CONTAINER_CASE" >&2
      exit 2
      ;;
  esac

  for machine in "${machines[@]}"; do
    export HOME="$test_root/home-$machine"
    export CODEX_HOME="$HOME/.codex"
    mkdir -p "$HOME"
    CODEX_MANAGED_MACHINE="$machine" /repo/install.sh --headless >/dev/null

    test -f "$CODEX_HOME/config.toml"
    test -f "$CODEX_HOME/AGENTS.md"
    test "$(cat "$HOME/.config/codex/managed-machine")" = "$machine"
    test -f "$HOME/.docker/mcp/catalogs/docker-official.json"
    test -f "$AGENTS_HOME/skills/impeccable/SKILL.md"
    grep -Fq 'npx skills add pbakaus/impeccable -g -a codex -s impeccable -y' "$MOCK_LOG"
    if [[ "$machine" == macos-* ]]; then
      grep -Fq '"--secrets", "docker-desktop"' "$CODEX_HOME/config.toml"
    else
      grep -Fq 'docker-mcp.env' "$CODEX_HOME/config.toml"
      test -x "$HOME/.docker/cli-plugins/docker-mcp"
    fi
    printf 'passed full install/update: %s on %s container\n' "$machine" "$CODEX_CONTAINER_CASE"
  done
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
docker run --rm -e CODEX_CONTAINER_CASE=ubuntu -v "$repo_root:/repo:ro" ubuntu:24.04 \
  bash -lc '/repo/tests/test-codex-managed-containers.sh'
docker run --rm -e CODEX_CONTAINER_CASE=arch -v "$repo_root:/repo:ro" archlinux:latest \
  bash -lc '/repo/tests/test-codex-managed-containers.sh'
docker run --rm -e CODEX_CONTAINER_CASE=macos -v "$repo_root:/repo:ro" bash:3.2 \
  /repo/tests/test-codex-managed-containers.sh
