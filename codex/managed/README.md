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

The shared `cx` shell function installs `@openai/codex@latest` when Codex is missing and applies managed configuration before every launch. Once per 24 hours, it checks managed dependencies and updates only missing or stale entries. The dotfiles installer records its completed update, so the next `cx` launch does not repeat it. Failed checks are reported and throttled for the same period, but an existing Codex installation still launches. Set `CX_SYNC_ALWAYS=1` for a forced check, or run `codex-sync update` directly at any time. Codex then starts with `--yolo`.

`apply` concatenates three non-overlapping TOML layers and generates the Docker MCP Gateway entry from server manifests:

1. `shared/config.toml`
2. `profiles/work.toml` or `profiles/personal.toml`
3. `machines/<machine>.toml`
4. `docker-mcp/shared.servers`

It validates the result with Codex's strict configuration parser, backs up a changed active configuration, and installs `config.toml` and `AGENTS.md` under `$CODEX_HOME`.

`update` applies the configuration, updates Docker MCP Gateway on Linux only when its tagged release is stale, compares installed npm package versions with current releases, uses the Skills CLI's targeted update check, and installs missing declared plugins. User-installed Codex apps, plugins, marketplaces, and skills are not removed. Docker Desktop manages the gateway plugin on macOS. During each apply, current hook hashes are trusted only when their plugin is declared in `dependencies.conf`; unrelated project hooks retain Codex's normal trust prompts.

The dotfiles installer runs this full update. Existing Codex configuration is backed up and replaced, so rerunning `install.sh` reconciles a machine rather than preserving stale MCP servers, skills, plugins, or hooks.

`doctor` reads and validates the managed installation without changing it. Missing user-owned MCP credentials and runtime settings are informational, not failures. It runs `codex doctor` when an active configuration exists.

## Shared SDLC baseline

- Docker MCP Gateway with Playwright on every machine
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

The updater compares Matt-owned entries in the Skills CLI lock with the current upstream suite, removing skills deleted upstream so old machines do not retain a different managed set indefinitely. Its exclusion list prevents `obsidian-vault` from being installed even temporarily, while the legacy removal entry cleans it from machines that predate source metadata. Unrelated integrations remain untouched.

`ui-ux-pro-max` is removed only after Impeccable is installed and verified. Impeccable owns broad product and brand design work. The Emil skills activate for motion-specific tasks, Vercel's skill owns React performance guidance, and `design-taste-frontend` should be invoked explicitly for landing pages or portfolios rather than as a second general design system.

## Tests

`tests/test-codex-managed.sh` exercises real rendering plus failure paths for dependency input, clean Codex installation, and launcher availability. `tests/test-codex-managed-containers.sh` runs the full installer and managed update filesystem flow for Ubuntu and Omarchy profiles in Ubuntu and Arch containers. It exercises both macOS profiles with Bash 3.2 plus simulated Darwin and Docker Desktop commands. Network installers and Docker are replaced with deterministic local commands; the host suite tests the Python helpers. Docker cannot reproduce a real macOS kernel or BSD userland, so final native macOS validation still runs on a Mac.

## Secrets

Never put API keys or tokens in tracked files. STDIO MCP servers receive named variables with `env_vars`; HTTP MCP servers should use OAuth or an environment-backed bearer token.

Docker's `default` profile owns server configuration and authentication. Configure secrets, OAuth, URLs, and usernames through Docker MCP Toolkit on each machine. The managed updater adds missing shared servers to that profile but never removes extra local servers or overwrites their configuration.

## Docker MCP Gateway

Track only authored server selections, catalogues, registry selections, profiles, and tool policies. Do not track `mcp-toolkit.db`, migration locks, generated catalogues, or backup files.

The central Docker MCP set is Playwright. `codex-sync update` adds any missing centrally managed servers to Docker's `default` profile without removing, replacing, filtering, or reconfiguring servers already there. Docker MCP has no work/personal layering. Codex connects with `docker mcp gateway run --profile default`, so Docker Desktop's local profile, tool allow-list, and secrets remain authoritative. GitHub is supplied through the shared OpenAI-curated GitHub plugin.

Docker Desktop 4.59 or later supplies the MCP Toolkit on macOS when the feature is enabled. Docker Engine hosts need the `docker-mcp` CLI plugin installed under `~/.docker/cli-plugins`. `codex-sync doctor` reports whether the gateway plugin is available.
