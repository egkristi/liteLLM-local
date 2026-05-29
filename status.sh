#!/usr/bin/env bash
set -uo pipefail

PORT="${PORT:-4000}"
URL="http://localhost:$PORT"

echo "=== LiteLLM Local Status ==="
echo "Endpoint: $URL"
echo ""

# Check if proxy is reachable
if ! curl -sf "$URL" &>/dev/null; then
  echo "Status: ❌ Not running (no response on port $PORT)"
  echo "Start it with: ./start.sh"
  exit 1
fi

echo "Status: ✅ Running"
echo ""

# List available models
echo "Available models:"
curl -sf "$URL/v1/models" 2>/dev/null | python3 -c '
import sys, json
data = json.load(sys.stdin)
for m in data.get("data", []):
    model_id = m["id"]
    print(f"  - {model_id}")
' 2>/dev/null || echo "  (could not parse model list)"

echo ""
echo "Health check:"
curl -sf "$URL/health" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "  (health endpoint not available)"
