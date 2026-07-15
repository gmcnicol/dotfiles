# Codex and Docker MCP configuration staging

Temporary, local-only staging area for collecting configuration from four machines before comparing and consolidating it.

## Layout

- `codex/` — Codex configuration, including MCPs, skills, plugins, instructions, and other settings.
- `docker-mcp/` — Docker MCP Gateway configuration, compose files, catalogs, policies, and related notes.

Machine folders:

- `macos-work-laptop`
- `macos-personal-macmini`
- `omarchy-laptop`
- `ubuntu-server`

## Safety

- Do not copy secrets, API keys, OAuth tokens, private keys, or credential databases here.
- Redact secret values while preserving key names and structure.
- Keep source paths and notes in each machine's `MANIFEST.md`.
- This directory is disposable and is not intended to become the canonical configuration.

## Suggested collection

For each machine, copy or export the relevant files into its matching folder, then add:

1. `MANIFEST.md` — source paths, OS, versions, and anything intentionally omitted.
2. `REDACTIONS.md` — names of redacted secrets or machine-specific values.
3. `NOTES.md` — differences, uncertainties, and desired behavior.

After collection, we can compare the four trees, identify a canonical baseline, and produce forward-only changes for the real dotfiles/configuration.
