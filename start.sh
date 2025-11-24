#!/usr/bin/env bash
set -e

N8N_PORT="${N8N_PORT:-5678}"
N8N_USER_FOLDER="${N8N_USER_FOLDER:-/home/node/.n8n}"
mkdir -p "$N8N_USER_FOLDER"
chown -R node:node "$N8N_USER_FOLDER" || true

export N8N_PORT
export N8N_USER_FOLDER

# Start n8n in background
if command -v gosu >/dev/null 2>&1; then
  gosu node n8n start --port "$N8N_PORT" > /var/log/n8n.log 2>&1 &
else
  n8n start --port "$N8N_PORT" > /var/log/n8n.log 2>&1 &
fi

sleep 2

PORT="${PORT:-10000}"
export FLASK_ENV=production
exec gunicorn --bind "0.0.0.0:${PORT}" --workers 1 app:app
