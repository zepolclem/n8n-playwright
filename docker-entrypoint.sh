#!/bin/sh
set -eu

N8N_NODES_DIR="/home/node/.n8n/nodes"
PLAYWRIGHT_PACKAGE="n8n-nodes-playwright"
PLAYWRIGHT_TGZ="/opt/n8n/community/${PLAYWRIGHT_PACKAGE}.tgz"

mkdir -p "$N8N_NODES_DIR"

if [ ! -d "$N8N_NODES_DIR/node_modules/$PLAYWRIGHT_PACKAGE" ]; then
  echo "Installing $PLAYWRIGHT_PACKAGE into $N8N_NODES_DIR"
  npm install --prefix "$N8N_NODES_DIR" --omit=dev --ignore-scripts "$PLAYWRIGHT_TGZ"
fi

exec "$@"
