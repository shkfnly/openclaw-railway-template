#!/bin/bash
set -e

chown -R openclaw:openclaw /data
chmod 700 /data

if [ ! -d /data/.linuxbrew ]; then
  cp -a /home/linuxbrew/.linuxbrew /data/.linuxbrew
fi

rm -rf /home/linuxbrew/.linuxbrew
ln -sfn /data/.linuxbrew /home/linuxbrew/.linuxbrew

# Add cortex-engine MCP server to openclaw config
CONFIG_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
mkdir -p "$CONFIG_DIR"

node -e "
const fs = require('fs');
const configPath = '$CONFIG_FILE';
let config = {};
if (fs.existsSync(configPath)) {
  try { config = JSON.parse(fs.readFileSync(configPath, 'utf8')); } catch(e) { config = {}; }
}
if (!config.mcpServers) config.mcpServers = {};
// Only add if not already present
if (!config.mcpServers['cortex-engine']) {
  config.mcpServers['cortex-engine'] = {
    command: 'npx',
    args: ['@fozikio/cortex-engine']
  };
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log('[setup] cortex-engine MCP server added to config');
} else {
  console.log('[setup] cortex-engine MCP server already configured');
}
" 2>&1 || echo "[setup] Warning: could not configure cortex-engine MCP server"

chown -R openclaw:openclaw "$CONFIG_DIR" 2>/dev/null || true

exec gosu openclaw node src/server.js
