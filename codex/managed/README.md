# Managed Codex configuration

This directory is the canonical, non-secret Codex configuration shared across Gareth's machines. It replaces copying live `~/.codex` trees, plugin caches, and Docker MCP databases between hosts.

## Interface

```bash
codex-sync install
codex-sync apply
codex-sync update
codex-sync doctor
```

`install` and `update` both perform the full authoritative reconciliation.

`codex-sync` asks which machine it is configuring when run interactively. The dotfiles installer asks the same question once and records the answer for `cx`, which passes the override only to its own sync calls. Direct interactive `codex-sync` calls still prompt. Set `CODEX_MANAGED_MACHINE` for non-interactive installs and syncs, or to render another machine's configuration.

The shared `cx` shell function compares the installed Codex version with npm, silently installs `@openai/codex@latest` only when required, and applies managed configuration before every launch. It refreshes the slower dependencies when the last successful sync is more than 24 hours old. Set `CX_SYNC_ALWAYS=1` for a forced full update, or run `codex-sync update` directly at any time. A failed apply or update prevents `cx` from launching a drifted environment. Codex then starts with `--yolo`.

`apply` concatenates three non-overlapping TOML layers and generates the Docker MCP Gateway entry from server manifests:

1. `shared/config.toml`
2. `profiles/work.toml` or `profiles/personal.toml`
3. `machines/<machine>.toml`
4. `docker-mcp/shared.servers` plus `docker-mcp/profiles/<profile>.servers`

It validates the result with Codex's strict configuration parser, backs up a changed active configuration, and installs `config.toml` and `AGENTS.md` under `$CODEX_HOME`.

`update` applies the configuration, refreshes the tagged Docker MCP Gateway release on Linux, downloads Docker's curated MCP catalogue, updates Codex through npm when required, replaces global Codex skills with the declared set, and removes undeclared plugins and plugin marketplaces. Docker Desktop manages the gateway plugin on macOS. During each apply, current hook hashes are trusted only when their plugin is declared in `dependencies.conf`; unrelated project hooks retain Codex's normal trust prompts.

The dotfiles installer runs this full update. Existing Codex configuration is backed up and replaced, so rerunning `install.sh` reconciles a machine rather than preserving stale MCP servers, skills, plugins, or hooks.

`doctor` validates the render, checks required commands, and runs `codex doctor` when an active configuration exists.

## Shared SDLC baseline

- Docker MCP Gateway with Context7, Notion, and Playwright on every machine
- A shared direct Codegraph MCP server on every machine
- Ponytail instructions and lifecycle hooks
- GitHub plugin
- Matt Pocock's current skills suite, dynamically discovered with the Obsidian integration excluded
- `juliusbrussee/caveman` at full intensity by default for token-efficient responses without another hook runtime
- `find-docs` and `find-skills` from `vercel-labs/skills`
- Impeccable as the primary UI design workflow and project design-language keeper
- Emil Kowalski's scoped motion vocabulary, opportunity, planning, review, and design-engineering skills
- Vercel React best practices for implementation quality
- `design-taste-frontend` for explicitly requested landing-page and portfolio aesthetics

Skill, plugin, and Codegraph package sources are declared in `dependencies.conf`. The Skills CLI records exact installed metadata in the user-level `~/.agents/.skill-lock.json`; that generated lock and the installed skill copies remain outside this repository.

Skills previously installed directly under `$CODEX_HOME/skills` are mapped to their managed replacements in `legacy-skills.conf`. After `codex-sync update` verifies the replacement exists under `~/.agents/skills`, it removes the legacy copy so Codex sees exactly one installation.

The updater compares Matt-owned entries in the Skills CLI lock with the current upstream suite, removing skills deleted upstream so old machines do not retain a different set indefinitely. Its exclusion list prevents `obsidian-vault` from being installed even temporarily, while the legacy removal entry cleans it from machines that predate source metadata. Applying or checking the managed configuration also purges generated Linear and Obsidian marketplace cache directories.

`ui-ux-pro-max` is intentionally removed before Impeccable is installed. Impeccable owns broad product and brand design work. The Emil skills activate for motion-specific tasks, Vercel's skill owns React performance guidance, and `design-taste-frontend` should be invoked explicitly for landing pages or portfolios rather than as a second general design system.

## Secrets

Never put API keys or tokens in tracked files. STDIO MCP servers receive named variables with `env_vars`; HTTP MCP servers should use OAuth or an environment-backed bearer token. Managed Docker MCP secrets belong in the untracked local environment file described below.

`codex-sync apply` creates `~/.config/codex/docker-mcp.env` with mode `0600` when it is missing. Populate it using the Docker secret names from `docker-mcp/secrets.env.example`. Context7 runs without an API key. The same file-backed secret mechanism is used on macOS and Linux.

On the work MacBook, configure Jira before applying on a clean machine:

```bash
CODEX_JIRA_URL="https://example.atlassian.net" \
CODEX_JIRA_USERNAME="name@example.com" \
codex-sync apply
```

Optional `CODEX_CONFLUENCE_URL` and `CODEX_CONFLUENCE_USERNAME` variables add Confluence. Tokens remain only in `docker-mcp.env`; URLs and usernames are written to the dedicated local `~/.docker/mcp/codex-managed-config.yaml` and are not committed. The manager does not overwrite Docker Desktop's general `config.yaml`.

## Docker MCP Gateway

Track only authored server selections, catalogues, registry selections, profiles, and tool policies. Do not track `mcp-toolkit.db`, migration locks, generated catalogues, or backup files.

The shared Docker MCP set is Context7, Notion, and Playwright. Every gateway invocation explicitly uses `docker-official.json`, refreshed from Docker's curated catalogue URL by `codex-sync update`. The refresh removes the Linear and Obsidian server definitions before installing the local catalogue. GitHub is supplied consistently through the shared OpenAI-curated GitHub plugin rather than duplicated inside the gateway. The work profile adds Atlassian for Jira and Confluence through the same Docker MCP Gateway transport. The updater rejects selected servers that are missing from the curated catalogue. A capability must not be configured as a direct MCP on one machine and a Docker MCP on another. Add it to the appropriate Docker server manifest or leave it out until a Docker-backed definition exists.

Docker Desktop 4.59 or later supplies the MCP Toolkit on macOS when the feature is enabled. Docker Engine hosts need the `docker-mcp` CLI plugin installed under `~/.docker/cli-plugins`. `codex-sync doctor` reports whether the gateway plugin is available.

## NUC Penpot service

The Ubuntu server profile adds one direct HTTP MCP entry for Penpot at `http://127.0.0.1:4401/mcp`. The endpoint is supplied by the persistent Docker service in `docker/penpot-mcp`, so Penpot remains container-installed without pretending its browser-facing lifecycle fits Docker MCP Gateway. `codex-sync update` resolves the current `@penpot/mcp@stable` version, rebuilds the image, and recreates the service. `codex-sync doctor` verifies the LAN plugin manifest, advertised WebSocket address, and MCP handshake.
