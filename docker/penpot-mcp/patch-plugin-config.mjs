import { readFileSync, writeFileSync } from "node:fs";

const configPath = "/opt/penpot-mcp/packages/plugin/vite.config.ts";
const source = readFileSync(configPath, "utf8");
const original = "        allowedHosts: [],";
const replacement =
    '        allowedHosts: (process.env.PENPOT_MCP_PLUGIN_ALLOWED_HOSTS ?? "localhost").split(","),';

if (source.split(original).length !== 2) {
    throw new Error("The Penpot plugin allow-list patch no longer applies cleanly");
}

writeFileSync(configPath, source.replace(original, replacement));
