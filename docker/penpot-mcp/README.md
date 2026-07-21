# Penpot MCP on the NUC

This persistent Docker service runs the stable Penpot MCP package for the NUC profile. It is separate from Docker MCP Gateway because the Penpot browser plugin needs long-lived HTTP and WebSocket ports.

`codex-sync update` resolves the current npm `stable` version, builds the image, and starts the service on the NUC.

## Connections

- Load `http://nuc:4400/manifest.json` in Penpot using **Plugins → Load from URL**.
- Keep the plugin window open and click **Connect to MCP server**.
- The compiled plugin connects to `ws://nuc:4402` by default.
- Codex on the NUC connects locally to `http://127.0.0.1:4401/mcp`.

Set both public-host variables before running Compose if clients reach the NUC through a different hostname:

```bash
PENPOT_MCP_PLUGIN_ALLOWED_HOST=nuc.local \
PENPOT_MCP_WEBSOCKET_URL=ws://nuc.local:4402 \
docker compose up -d --build
```

The service uses Penpot remote mode because the browser is on another machine. Remote mode disables Penpot MCP filesystem tools. Ports 4400 and 4402 are exposed to the LAN; port 4401 is bound only to the NUC loopback interface.

The plugin and WebSocket endpoints do not add authentication. Keep ports 4400 and 4402 on a trusted LAN or private overlay network and do not publish them to the internet.

Penpot 2.15.4's plugin preview server rejects LAN hostnames even when it binds to all interfaces. The image applies a guarded source patch that reads `PENPOT_MCP_PLUGIN_ALLOWED_HOSTS`; the build fails if an upstream release changes the expected source instead of silently producing an inaccessible plugin.
