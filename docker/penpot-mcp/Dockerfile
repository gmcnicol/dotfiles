FROM node:22-bookworm-slim

ARG PENPOT_MCP_VERSION

COPY patch-plugin-config.mjs /tmp/patch-plugin-config.mjs

RUN npm install --global "pnpm@10.31.0" \
    && mkdir -p /opt/penpot-mcp \
    && npm pack "@penpot/mcp@${PENPOT_MCP_VERSION}" --pack-destination /tmp \
    && tar -xzf "/tmp/penpot-mcp-${PENPOT_MCP_VERSION}.tgz" \
        --directory /opt/penpot-mcp --strip-components=1 \
    && node /tmp/patch-plugin-config.mjs \
    && pnpm --dir /opt/penpot-mcp --recursive install --no-frozen-lockfile \
    && pnpm --dir /opt/penpot-mcp --recursive run build \
    && chown -R node:node /opt/penpot-mcp \
    && npm cache clean --force

WORKDIR /opt/penpot-mcp
USER node

ENV NODE_ENV=production

EXPOSE 4400 4401 4402

CMD ["pnpm", "--recursive", "--parallel", "run", "start"]
