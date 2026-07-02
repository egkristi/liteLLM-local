#!/usr/bin/env python3
"""Caching proxy for LiteLLM Local.

Sits between clients and the LiteLLM proxy, caching chat completion responses
to avoid repeated API calls for identical prompts. Uses SQLite for persistence
with configurable TTL.

Usage:
    python3 cache-proxy.py                    # Start on port 4001, backend on 4000
    python3 cache-proxy.py --port 4001        # Custom frontend port
    python3 cache-proxy.py --backend 4000     # LiteLLM backend port
    python3 cache-proxy.py --ttl 3600         # Cache TTL in seconds (default: 1 hour)
    python3 cache-proxy.py --clear            # Clear all cached entries
    python3 cache-proxy.py --stats            # Show cache statistics
"""

import hashlib
import json
import os
import sqlite3
import sys
import threading
import time
import urllib.error
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from typing import Optional, Union

SCRIPT_DIR = Path(__file__).resolve().parent
CACHE_DB = SCRIPT_DIR / "logs" / "cache.db"
DEFAULT_TTL = 3600  # 1 hour
DEFAULT_PORT = 4001
BACKEND_PORT = int(os.environ.get("PORT", "4000"))


def init_db():
    """Create the cache database and table if they don't exist."""
    (SCRIPT_DIR / "logs").mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(CACHE_DB))
    conn.execute("""
        CREATE TABLE IF NOT EXISTS cache (
            hash TEXT PRIMARY KEY,
            response TEXT NOT NULL,
            model TEXT NOT NULL,
            created_at REAL NOT NULL,
            ttl REAL NOT NULL,
            hits INTEGER DEFAULT 1
        )
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_cache_expiry ON cache(created_at, ttl)
    """)
    conn.commit()
    conn.close()


def cache_key(body: bytes) -> str:
    """Generate a cache key from the request body."""
    return hashlib.sha256(body).hexdigest()


def get_cached(hash_key: str) -> Optional[str]:
    """Retrieve a cached response if it exists and hasn't expired."""
    conn = sqlite3.connect(str(CACHE_DB))
    cursor = conn.execute(
        "SELECT response, created_at, ttl FROM cache WHERE hash = ?",
        (hash_key,)
    )
    row = cursor.fetchone()
    if row:
        response, created_at, ttl = row
        if time.time() - created_at < ttl:
            # Increment hit counter
            conn.execute("UPDATE cache SET hits = hits + 1 WHERE hash = ?", (hash_key,))
            conn.commit()
            conn.close()
            return response
        else:
            # Expired — delete it
            conn.execute("DELETE FROM cache WHERE hash = ?", (hash_key,))
            conn.commit()
    conn.close()
    return None


def set_cached(hash_key: str, response: str, model: str, ttl: float):
    """Store a response in the cache."""
    conn = sqlite3.connect(str(CACHE_DB))
    conn.execute(
        "INSERT OR REPLACE INTO cache (hash, response, model, created_at, ttl, hits) VALUES (?, ?, ?, ?, ?, 1)",
        (hash_key, response, model, time.time(), ttl)
    )
    conn.commit()
    conn.close()


def clear_cache():
    """Delete all cached entries."""
    conn = sqlite3.connect(str(CACHE_DB))
    conn.execute("DELETE FROM cache")
    conn.commit()
    conn.close()
    print("✅ Cache cleared")


def cache_stats() -> dict:
    """Return cache statistics."""
    conn = sqlite3.connect(str(CACHE_DB))
    total = conn.execute("SELECT COUNT(*) FROM cache").fetchone()[0]
    expired = conn.execute(
        "SELECT COUNT(*) FROM cache WHERE ? - created_at >= ttl",
        (time.time(),)
    ).fetchone()[0]
    total_hits = conn.execute("SELECT COALESCE(SUM(hits), 0) FROM cache").fetchone()[0]
    models = conn.execute(
        "SELECT model, COUNT(*) as count, SUM(hits) as total_hits FROM cache GROUP BY model ORDER BY total_hits DESC"
    ).fetchall()
    conn.close()
    return {
        "total_entries": total,
        "expired_entries": expired,
        "total_hits": total_hits,
        "models": [{"model": m, "count": c, "hits": h} for m, c, h in models],
    }


class CacheHandler(BaseHTTPRequestHandler):
    """HTTP request handler that proxies to LiteLLM with caching."""

    # Silence default logging
    def log_message(self, format, *args):
        return

    def _proxy_request(self, body: Optional[bytes], path: str) -> tuple[bytes, int, dict]:
        """Forward a request to the LiteLLM backend.

        For GET/HEAD/DELETE requests, body should be None (no body sent).
        """
        url = f"http://localhost:{BACKEND_PORT}{path}"
        req = urllib.request.Request(
            url,
            data=body,
            headers={
                "Content-Type": "application/json",
                "Authorization": self.headers.get("Authorization", ""),
            },
            method=self.command,
        )
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return resp.read(), resp.status, dict(resp.headers)
        except urllib.error.HTTPError as e:
            return e.read(), e.code, dict(e.headers)
        except urllib.error.URLError as e:
            error_body = json.dumps({
                "error": {
                    "message": f"Backend proxy error: {e.reason}",
                    "type": "proxy_error",
                }
            }).encode()
            return error_body, 502, {"Content-Type": "application/json"}

    def _is_cacheable(self, path: str, body: bytes) -> bool:
        """Determine if a request should be cached."""
        # Only cache chat completions
        if not path.endswith("/v1/chat/completions"):
            return False
        if self.command != "POST":
            return False
        try:
            data = json.loads(body)
            # Don't cache streaming requests
            if data.get("stream", False):
                return False
            return True
        except (json.JSONDecodeError, UnicodeDecodeError):
            return False

    def _get_model(self, body: bytes) -> str:
        """Extract model name from request body."""
        try:
            data = json.loads(body)
            return data.get("model", "unknown")
        except (json.JSONDecodeError, UnicodeDecodeError):
            return "unknown"

    def do_GET(self):
        # GET requests have no body — pass None explicitly
        resp_body, status, headers = self._proxy_request(None, self.path)
        self._send_response(resp_body, status, headers)

    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))

        # Check cache for cacheable requests
        if self._is_cacheable(self.path, body):
            key = cache_key(body)
            cached = get_cached(key)
            if cached is not None:
                resp_body = cached.encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("X-Cache", "HIT")
                self.send_header("Content-Length", str(len(resp_body)))
                self.end_headers()
                self.wfile.write(resp_body)
                return

        # Forward to backend
        resp_body, status, headers = self._proxy_request(body, self.path)

        # Cache successful responses
        if status == 200 and self._is_cacheable(self.path, body):
            model = self._get_model(body)
            ttl = float(os.environ.get("LITELLM_CACHE_TTL", str(DEFAULT_TTL)))
            set_cached(cache_key(body), resp_body.decode("utf-8"), model, ttl)

        self._send_response(resp_body, status, headers)

    def _send_response(self, resp_body: bytes, status: int, headers: dict):
        self.send_response(status)
        self.send_header("Content-Type", headers.get("Content-Type", "application/json"))
        self.send_header("X-Cache", "MISS")
        self.send_header("Content-Length", str(len(resp_body)))
        # Forward CORS headers if present
        for h in ["Access-Control-Allow-Origin", "Access-Control-Allow-Methods",
                   "Access-Control-Allow-Headers"]:
            if h in headers:
                self.send_header(h, headers[h])
        self.end_headers()
        self.wfile.write(resp_body)

    def do_OPTIONS(self):
        """Handle CORS preflight."""
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()


def main():
    import argparse

    global BACKEND_PORT

    parser = argparse.ArgumentParser(
        prog="cache-proxy",
        description="Caching proxy for LiteLLM Local",
    )
    parser.add_argument("--port", type=int, default=DEFAULT_PORT,
                        help=f"Frontend port (default: {DEFAULT_PORT})")
    parser.add_argument("--backend", type=int, default=BACKEND_PORT,
                        help=f"LiteLLM backend port (default: {BACKEND_PORT})")
    parser.add_argument("--ttl", type=int, default=DEFAULT_TTL,
                        help=f"Cache TTL in seconds (default: {DEFAULT_TTL})")
    parser.add_argument("--clear", action="store_true", help="Clear all cached entries")
    parser.add_argument("--stats", action="store_true", help="Show cache statistics")

    args = parser.parse_args()

    BACKEND_PORT = args.backend

    if args.clear:
        init_db()
        clear_cache()
        return

    if args.stats:
        init_db()
        stats = cache_stats()
        print(f"Total entries:  {stats['total_entries']}")
        print(f"Expired:        {stats['expired_entries']}")
        print(f"Total hits:     {stats['total_hits']}")
        print(f"By model:")
        for m in stats['models']:
            print(f"  {m['model']}: {m['count']} entries, {m['hits']} hits")
        return

    os.environ["LITELLM_CACHE_TTL"] = str(args.ttl)
    init_db()

    server = HTTPServer(("", args.port), CacheHandler)
    print(f"🚀 Cache proxy listening on http://localhost:{args.port}")
    print(f"   Backend: http://localhost:{args.backend}")
    print(f"   Cache TTL: {args.ttl}s")
    print(f"   Cache DB: {CACHE_DB}")
    print(f"   (Use --clear to clear cache, --stats for statistics)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down cache proxy...")
        server.shutdown()


if __name__ == "__main__":
    main()
