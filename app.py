# app.py (minimal proxy: only "/" -> n8n, and "/alive/")
import os
from flask import Flask, request, Response
import requests
from flask import stream_with_context

app = Flask(__name__)

N8N_HOST = os.environ.get("N8N_HOST", "127.0.0.1")
N8N_PORT = int(os.environ.get("N8N_PORT", 5678))
N8N_BASE = f"http://{N8N_HOST}:{N8N_PORT}"

@app.route("/alive/", methods=["GET", "HEAD"])
def alive():
    return ("OK", 200)

# only proxy the root path "/" (all methods)
@app.route("/", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"])
def proxy_root():
    target_url = f"{N8N_BASE}/"

    # forward headers (strip host)
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
            timeout=60,
        )
    except requests.exceptions.RequestException as e:
        return (f"Upstream request failed: {e}", 502)

    excluded_headers = ["content-encoding", "content-length", "transfer-encoding", "connection"]
    response_headers = [(name, value) for name, value in resp.raw.headers.items() if name.lower() not in excluded_headers]

    return Response(stream_with_context(resp.iter_content(chunk_size=8192)), status=resp.status_code, headers=response_headers)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
