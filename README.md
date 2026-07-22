# Dotfiles

## Managed Codex configuration

The canonical shared, work, personal, and machine-specific Codex configuration lives in [`codex/managed`](codex/managed). Use `codex-sync` to apply, update, or validate Codex, shared skills, Ponytail hooks, MCP servers, and profile-specific integrations.

`codex-sync update` reconciles the complete current Matt Pocock skill suite, excluding `obsidian-vault`, so newly added upstream skills arrive without maintaining a static allow-list. It also removes Obsidian and Linear caches after plugin updates.

The shared skill baseline installs the maintained `juliusbrussee/caveman` skill and enables full intensity by default. Impeccable supplies the main UI workflow, supported by scoped Emil Kowalski motion skills, Vercel React best practices, and explicit-use design taste for landing pages or portfolios. Ponytail remains the single hook runtime.

## Local configuration snapshots

Temporary, local-only staging area for collecting configuration from four machines before comparing and consolidating it.

## Layout

- `codex/`: Codex configuration, including MCPs, skills, plugins, instructions, and other settings.
- `docker-mcp/`: Docker MCP Gateway configuration, compose files, catalogues, policies, and related notes.

Machine folders:

- `macos-work-laptop`
- `macos-personal-macmini`
- `omarchy-laptop`
- `ubuntu-server`

## Safety

- Do not copy secrets, API keys, OAuth tokens, private keys, or credential databases here.
- Redact secret values while preserving key names and structure.
- Keep source paths and notes in each machine's `MANIFEST.md`.
- The ignored machine snapshot directories are disposable and are not canonical configuration.

## Suggested collection

For each machine, copy or export the relevant files into its matching folder, then add:

1. `MANIFEST.md`: source paths, OS, versions, and anything intentionally omitted.
2. `REDACTIONS.md`: names of redacted secrets or machine-specific values.
3. `NOTES.md`: differences, uncertainties, and desired behaviour.

After collection, we can compare the four trees, identify a canonical baseline, and produce forward-only changes for the real dotfiles/configuration.
