import os
from flask import Flask, request, Response, stream_with_context, redirect
import requests

app = Flask(__name__)

N8N_HOST = os.environ.get("N8N_HOST", "127.0.0.1")
N8N_PORT = int(os.environ.get("N8N_PORT", 5678))
N8N_BASE = f"http://{N8N_HOST}:{N8N_PORT}"

@app.route("/alive/", methods=["GET", "HEAD"])
def alive():
    return ("OK", 200)

@app.route("/", methods=["GET"])
def root():
    return redirect("/n8n/")

@app.route("/n8n/", defaults={"path": ""}, methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
@app.route("/n8n/<path:path>", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
def proxy(path):
    target_url = f"{N8N_BASE}/{path}"
    headers = {k: v for k, v in request.headers if k.lower() != "host"}
    try:
        resp = requests.request(
            method=request.method,
            url=target_url,
            headers=headers,
            params=request.args,
            data=request.get_data(),
            cookies=request.cookies,
            allow_redirects=False,
            stream=True,
            timeout=30,
        )
    except requests.exceptions.RequestException as e:
        return (f"Upstream request failed: {e}", 502)

    excluded_headers = ["content-encoding", "content-length", "transfer-encoding", "connection"]
    response_headers = [(name, value) for name, value in resp.raw.headers.items() if name.lower() not in excluded_headers]

    return Response(stream_with_context(resp.iter_content(chunk_size=8192)), status=resp.status_code, headers=response_headers)

@app.route("/status/", methods=["GET"])
def status():
    try:
        r = requests.get(f"{N8N_BASE}/healthz", timeout=3)
        if r.status_code == 200:
            return ("n8n OK", 200)
    except Exception:
        pass
    return ("n8n not reachable", 502)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
