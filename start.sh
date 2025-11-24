#!/usr/bin/env bash
set -e

N8N_PORT="${N8N_PORT:-5678}"
N8N_USER_FOLDER="${N8N_USER_FOLDER:-/home/node/.n8n}"
mkdir -p "$N8N_USER_FOLDER" || true
chown -R node:node "$N8N_USER_FOLDER" || true

export N8N_PORT
export N8N_USER_FOLDER

# Start n8n in background
if command -v gosu >/dev/null 2>&1; then
  gosu node n8n start --port "$N8N_PORT" > /var/log/n8n.log 2>&1 &
else
  n8n start --port "$N8N_PORT" > /var/log/n8n.log 2>&1 &
fi

# Wait for n8n to start (attempt to connect up to 30 seconds)
python3 - <<PY
import socket, time, os, sys
host = os.environ.get("N8N_HOST", "127.0.0.1")
port = int(os.environ.get("N8N_PORT", 5678))
start = time.time()
timeout = 30
while True:
    s = socket.socket()
    s.settimeout(1)
    try:
        s.connect((host, port))
        s.close()
        print("n8n reachable on {}:{}".format(host, port))
        break
    except Exception:
        if time.time() - start > timeout:
            print("Timeout waiting for n8n ({}s)".format(timeout))
            # print last lines of log for debugging (if available)
            try:
                with open("/var/log/n8n.log","r") as f:
                    lines = f.readlines()[-40:]
                    print("---- n8n log (last lines) ----")
                    print("".join(lines))
            except Exception:
                pass
            sys.exit(1)
        time.sleep(1)
PY

# Start the Flask proxy (bind to Render's PORT)
PORT="${PORT:-10000}"
export FLASK_ENV=production
exec gunicorn --bind "0.0.0.0:${PORT}" --workers 1 app:app
