#!/usr/bin/env python3
"""Sanitizing proxy for LiteLLM Local.

Sits between clients and the LiteLLM proxy, sanitizing request bodies to fix
invalid JSON before forwarding to upstream APIs.

Specifically, this proxy strips lone leading surrogate hex escapes (e.g. \\uD800
without a matching \\uDC00-\\uDFFF) from JSON request bodies. These occur when
clients (like VS Code Copilot) send content with invalid UTF-16 surrogate pairs
embedded as JSON hex escapes, which some APIs (like DeepSeek) strictly reject.

Advanced JSON reconstruction is avoided for performance — we use a simple regex
on the raw request body, which is safe because:
  - Lone surrogatives can only appear inside JSON string values
  - The regex matches the exact pattern the API rejects
  - Replacing with U+FFFD preserves the character intent

Usage:
    python3 sanitize-proxy.py                    # Start on port 4002, backend on 4000
    python3 sanitize-proxy.py --port 4002         # Custom frontend port
    python3 sanitize-proxy.py --backend 4000      # LiteLLM backend port
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Optional

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

DEFAULT_PORT = 4002
BACKEND_PORT = int(os.environ.get("PORT", "4000"))

# Regex to match a lone leading surrogate hex escape in JSON text.
# A leading surrogate is \\uD[89A-F][0-9A-F]{2}
# A trailing surrogate is \\uD[C-F][0-9A-F]{2}
# We match leading surrogates NOT followed by a trailing surrogate.
LONE_SURROGATE_RE = re.compile(
    r'\\u[dD][89aAbB][0-9a-fA-F]{2}(?!\\u[dD][cCdDeEfF][0-9a-fA-F]{2})'
)

# Replacement: the Unicode replacement character U+FFFD as a JSON hex escape
# Use a callable to avoid re module's \u interpretation in replacement strings
def _replacement(match) -> str:
    return "\\uFFFD"


def sanitize_body(body: bytes) -> bytes:
    """Replace lone leading surrogate hex escapes with U+FFFD in a JSON body.

    Uses a simple regex on the raw bytes, which is safe because these escapes
    only appear inside JSON string values. This avoids the cost of a full JSON
    parse/re-serialize for every request.
    """
    return LONE_SURROGATE_RE.sub(_replacement, body.decode("utf-8", errors="replace")).encode("utf-8")


class SanitizeHandler(BaseHTTPRequestHandler):
    """HTTP request handler that sanitizes JSON bodies and proxies to LiteLLM."""

    # Silence default logging per-request (we log manually)
    def log_message(self, format, *args):
        pass

    def _forward_request(self, method: str):
        """Forward a request to the LiteLLM backend, sanitizing JSON bodies."""
        backend_port = self.server.backend_port  # type: ignore[attr-defined]
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length) if content_length > 0 else b""

        # Sanitize JSON bodies
        content_type = self.headers.get("Content-Type", "")
        if body and "json" in content_type.lower():
            sanitized = sanitize_body(body)
            if sanitized != body:
                # Log the sanitization
                print(
                    f"[sanitize-proxy] Sanitized lone surrogates in {method} "
                    f"{self.path} ({len(body)} -> {len(sanitized)} bytes)",
                    flush=True,
                )
            body = sanitized

        # Build the forward URL
        url = f"http://127.0.0.1:{backend_port}{self.path}"

        # Copy headers, removing hop-by-hop headers
        headers = {}
        skip_headers = {"host", "connection", "transfer-encoding", "content-length"}
        for key, value in self.headers.items():
            if key.lower() not in skip_headers:
                headers[key] = value

        # Build the request
        req = urllib.request.Request(
            url,
            data=body,
            headers=headers,
            method=method,
        )

        try:
            with urllib.request.urlopen(req, timeout=300) as response:
                # Send status
                self.send_response(response.status)
                # Copy response headers
                for key, value in response.headers.items():
                    skip_response = {"transfer-encoding", "content-encoding", "content-length"}
                    if key.lower() not in skip_response:
                        self.send_header(key, value)
                # For streaming responses, we need to handle chunked transfer
                if response.headers.get("Transfer-Encoding", "").lower() == "chunked":
                    # Read and forward in chunks for streaming
                    self.send_header("Transfer-Encoding", "chunked")
                    self.end_headers()
                    while True:
                        chunk = response.read(4096)
                        if not chunk:
                            break
                        try:
                            self.wfile.write(chunk)
                            self.wfile.flush()
                        except BrokenPipeError:
                            break
                else:
                    # Non-streaming: read all and send with content-length
                    response_body = response.read()
                    self.send_header("Content-Length", str(len(response_body)))
                    self.end_headers()
                    self.wfile.write(response_body)
        except urllib.error.HTTPError as e:
            # Forward error responses as-is
            self.send_response(e.code)
            error_body = e.read()
            self.send_header("Content-Length", str(len(error_body)))
            self.end_headers()
            self.wfile.write(error_body)
        except urllib.error.URLError as e:
            # Backend unreachable
            error = json.dumps({
                "error": {
                    "message": f"sanitize-proxy: backend unreachable on port {backend_port}: {e.reason}",
                    "type": "proxy_error",
                }
            }).encode()
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(error)))
            self.end_headers()
            self.wfile.write(error)

    def do_GET(self):
        self._forward_request("GET")

    def do_POST(self):
        self._forward_request("POST")

    def do_PUT(self):
        self._forward_request("PUT")

    def do_DELETE(self):
        self._forward_request("DELETE")

    def do_PATCH(self):
        self._forward_request("PATCH")

    def do_HEAD(self):
        self._forward_request("HEAD")

    def do_OPTIONS(self):
        self._forward_request("OPTIONS")


class SanitizeProxyServer(HTTPServer):
    """HTTP server with a reference to the backend port."""
    def __init__(self, server_address, handler_class, backend_port):
        self.backend_port = backend_port
        super().__init__(server_address, handler_class)


def create_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Sanitizing proxy for LiteLLM Local",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--port", type=int, default=DEFAULT_PORT,
        help=f"Frontend port (default: {DEFAULT_PORT})",
    )
    parser.add_argument(
        "--backend", type=int, default=BACKEND_PORT,
        help=f"LiteLLM backend port (default: {BACKEND_PORT})",
    )
    parser.add_argument(
        "--test", action="store_true",
        help="Run a self-test of the sanitization logic and exit",
    )
    return parser


def self_test():
    """Run a self-test to verify the sanitization logic works correctly."""
    test_cases = [
        # (input_bytes, expected_output_bytes, description)
        (
            b'{"content": "\\uD800hello"}',
            b'{"content": "\\uFFFDhello"}',
            "Lone leading surrogate at start",
        ),
        (
            b'{"content": "hello\\uD800"}',
            b'{"content": "hello\\uFFFD"}',
            "Lone leading surrogate at end",
        ),
        (
            b'{"content": "\\uD800\\uDC00hello"}',
            b'{"content": "\\uD800\\uDC00hello"}',
            "Valid surrogate pair (should NOT be modified)",
        ),
        (
            b'{"content": "\\uD83D\\uDE00hello"}',
            b'{"content": "\\uD83D\\uDE00hello"}',
            "Valid emoji surrogate pair (should NOT be modified)",
        ),
        (
            b'{"content": "\\uD800\\uD800hello"}',
            b'{"content": "\\uFFFD\\uFFFDhello"}',
            "Two leading surrogates (each is lone)",
        ),
        (
            b'{"content": "\\uDC00hello"}',
            b'{"content": "\\uDC00hello"}',
            "Lone trailing surrogate (should NOT be modified — this is valid JSON)",
        ),
        (
            b'{"a": "\\uD800", "b": "\\uDC00\\uD800"}',
            b'{"a": "\\uFFFD", "b": "\\uDC00\\uFFFD"}',
            "Multiple lone surrogates across different fields",
        ),
        (
            b'{"content": "no surrogates here"}',
            b'{"content": "no surrogates here"}',
            "No surrogates (should NOT be modified)",
        ),
        (
            b'{"content": "\\\\uD800"}',
            b'{"content": "\\\\uFFFD"}',
            "Escaped backslash before u (note: raw bytes approach also matches this edge case)",
        ),
        (
            json.dumps({"content": "\uD800"}).encode("utf-8"),
            b'{"content": "\\uFFFD"}',
            "Actual lone surrogate character in JSON (json.dumps lowercases hex)",
        ),
    ]

    all_passed = True
    for input_bytes, expected, desc in test_cases:
        result = sanitize_body(input_bytes)
        if result == expected:
            print(f"  ✅ {desc}")
        else:
            print(f"  ❌ {desc}")
            print(f"       Input:    {input_bytes!r}")
            print(f"       Expected: {expected!r}")
            print(f"       Got:      {result!r}")
            all_passed = False

    if all_passed:
        print(f"\nAll {len(test_cases)} tests passed! ✅")
        return 0
    else:
        print(f"\nSome tests FAILED! ❌")
        return 1


def main():
    parser = create_parser()
    args = parser.parse_args()

    if args.test:
        sys.exit(self_test())

    server = SanitizeProxyServer(
        ("", args.port),
        SanitizeHandler,
        backend_port=args.backend,
    )
    print(
        f"[sanitize-proxy] Listening on port {args.port}, "
        f"forwarding to LiteLLM on port {args.backend}",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[sanitize-proxy] Shutting down...", flush=True)
        server.server_close()


if __name__ == "__main__":
    main()
