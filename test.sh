#!/usr/bin/env bash
set -uo pipefail

PORT="${PORT:-4000}"
URL="http://localhost:$PORT/v1/chat/completions"

echo "Sending smoke-test chat completion to $URL ..."

RESPONSE=$(curl -sf "$URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer anything" \
  -d '{
    "model": "deepseek-v4-pro",
    "messages": [{"role": "user", "content": "Say hello"}],
    "max_tokens": 10
  }' 2>/dev/null)

if [ -z "$RESPONSE" ]; then
  echo "❌ Smoke test FAILED — no response from proxy."
  echo "Make sure the proxy is running: ./start.sh"
  exit 1
fi

if echo "$RESPONSE" | grep -q '"error"'; then
  echo "❌ Smoke test FAILED — proxy returned an error:"
  echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
  exit 1
fi

if echo "$RESPONSE" | grep -q '"content"'; then
  echo "✅ Smoke test PASSED — proxy is working."
  CONTENT=$(echo "$RESPONSE" | python3 -c 'import sys,json; print(json.load(sys.stdin)["choices"][0]["message"]["content"].strip())' 2>/dev/null)
  echo "   Response: $CONTENT"
  exit 0
fi

echo "⚠️ Smoke test returned unexpected response:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
exit 1
