#!/usr/bin/env python3
"""Zero-dependency web UI for LiteLLM Local.

Serves a simple dashboard at http://localhost:8080 showing:
- Proxy status and health
- Available models
- Recent logs
- Usage / cost summary

Usage:
    ./webui.py           # start on port 8080
    PORT=8081 ./webui.py # start on custom port
"""

import json
import os
import urllib.request
from datetime import datetime
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
LOG_DIR = SCRIPT_DIR / "logs"
PROXY_PORT = os.environ.get("PORT", "4000")
WEBUI_PORT = int(os.environ.get("WEBUI_PORT", "8080"))


from typing import Optional, Union

def _proxy_json(path: str) -> Union[dict, list, None]:
    """Fetch JSON from the LiteLLM proxy using urllib (no curl dependency)."""
    try:
        url = f"http://localhost:{PROXY_PORT}{path}"
        with urllib.request.urlopen(url, timeout=5) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None


def proxy_status():
    """Check if the LiteLLM proxy is responding."""
    data = _proxy_json("/health")
    if data is not None:
        return data if isinstance(data, dict) else {"status": "ok", "raw": data}
    return {"status": "down", "error": "Proxy not responding"}


def list_models():
    """Fetch available models from the proxy."""
    data = _proxy_json("/v1/models")
    if data is not None and isinstance(data, dict):
        return [m["id"] for m in data.get("data", [])]
    return []


def recent_logs(n=100):
    """Read the most recent n lines from the latest log file."""
    if not LOG_DIR.exists():
        return []
    log_files = sorted(LOG_DIR.glob("*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not log_files:
        return []
    with open(log_files[0], "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    return lines[-n:]


def usage_summary():
    """Parse usage data from all log files."""
    if not LOG_DIR.exists():
        return {}
    total_requests = 0
    total_tokens = 0
    model_counts = {}
    for log_file in LOG_DIR.glob("*.log"):
        with open(log_file, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                if "completion_tokens" in line or "prompt_tokens" in line:
                    total_requests += 1
                if "model" in line:
                    # Very naive parsing — enough for a quick summary
                    for part in line.split():
                        if part.startswith("model="):
                            m = part.split("=", 1)[1].strip('"')
                            model_counts[m] = model_counts.get(m, 0) + 1
    return {
        "total_requests": total_requests,
        "model_counts": model_counts,
    }


HTML_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>LiteLLM Local Dashboard</title>
  <style>
    :root { --bg: #0d1117; --fg: #c9d1d9; --accent: #58a6ff; --ok: #3fb950; --warn: #d29922; --err: #f85149; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; background: var(--bg); color: var(--fg); margin: 0; padding: 2rem; line-height: 1.5; }
    h1 { margin-top: 0; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem; margin-bottom: 2rem; }
    .card { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1rem; }
    .card h2 { margin-top: 0; font-size: 1rem; text-transform: uppercase; letter-spacing: 0.05em; color: #8b949e; }
    .status-ok { color: var(--ok); }
    .status-warn { color: var(--warn); }
    .status-err { color: var(--err); }
    pre { background: #0d1117; border: 1px solid #30363d; border-radius: 6px; padding: 0.75rem; overflow-x: auto; font-size: 0.85rem; }
    ul { padding-left: 1.2rem; }
    .refresh { display: inline-block; margin-bottom: 1rem; padding: 0.4rem 0.8rem; background: var(--accent); color: #fff; text-decoration: none; border-radius: 6px; font-size: 0.9rem; }
    .refresh:hover { opacity: 0.9; }
  </style>
</head>
<body>
  <h1>LiteLLM Local Dashboard</h1>
  <a class="refresh" href="/">Refresh</a>

  <div class="grid">
    <div class="card">
      <h2>Proxy Status</h2>
      <p><strong>Port:</strong> {proxy_port}</p>
      <p><strong>Health:</strong> <span class="{health_class}">{health_status}</span></p>
      <pre>{health_json}</pre>
    </div>

    <div class="card">
      <h2>Models</h2>
      {models_html}
    </div>

    <div class="card">
      <h2>Usage Summary</h2>
      <p><strong>Requests (token lines):</strong> {total_requests}</p>
      <p><strong>Model breakdown:</strong></p>
      <ul>{model_counts_html}</ul>
    </div>
  </div>

  <div class="card">
    <h2>Recent Logs ({log_lines} lines)</h2>
    <pre>{logs}</pre>
  </div>

  <footer style="margin-top:2rem; color:#8b949e; font-size:0.85rem;">
    LiteLLM Local &middot; Dashboard served on port {webui_port}
  </footer>
</body>
</html>
"""


class DashboardHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()

            health = proxy_status()
            models = list_models()
            logs = recent_logs(100)
            usage = usage_summary()

            health_status = health.get("status", "unknown")
            health_class = (
                "status-ok" if health_status == "ok"
                else "status-warn" if health_status == "down"
                else "status-err"
            )

            models_html = (
                "<ul>" + "".join(f"<li>{m}</li>" for m in models) + "</ul>"
                if models else "<p>No models available. Is the proxy running?</p>"
            )

            model_counts_html = "".join(
                f"<li>{k}: {v}</li>" for k, v in usage.get("model_counts", {}).items()
            ) or "<li>No data yet</li>"

            html = HTML_TEMPLATE.format(
                proxy_port=PROXY_PORT,
                health_status=health_status,
                health_class=health_class,
                health_json=json.dumps(health, indent=2),
                models_html=models_html,
                total_requests=usage.get("total_requests", 0),
                model_counts_html=model_counts_html,
                log_lines=len(logs),
                logs="".join(logs) or "No logs found.",
                webui_port=WEBUI_PORT,
            )
            self.wfile.write(html.encode("utf-8"))
        else:
            self.send_error(404)

    def log_message(self, format, *args):
        # Suppress default request logging
        pass


def main():
    server = HTTPServer(("0.0.0.0", WEBUI_PORT), DashboardHandler)
    print(f"LiteLLM Local Dashboard running at http://localhost:{WEBUI_PORT}")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down.")
        server.shutdown()


if __name__ == "__main__":
    main()
