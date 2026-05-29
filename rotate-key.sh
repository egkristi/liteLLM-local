#!/usr/bin/env bash
# Rotate an API key in .env and restart the proxy.
# Usage: ./rotate-key.sh PROVIDER
#   ./rotate-key.sh deepseek
#   ./rotate-key.sh anthropic
#   make rotate-key PROVIDER=deepseek
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ $# -lt 1 ]; then
  echo "Usage: $0 PROVIDER"
  echo ""
  echo "Available providers (from .env.example):"
  grep -v '^#' .env.example | grep -v '^$' | sed 's/=.*//' | sed 's/_API_KEY//' | tr '[:upper:]' '[:lower:]' | while IFS= read -r provider; do
    [ -n "$provider" ] && echo "  - $provider"
  done
  exit 1
fi

PROVIDER=$(echo "$1" | tr '[:lower:]' '[:upper:]')
ENV_KEY="${PROVIDER}_API_KEY"

# Handle special cases
case "$PROVIDER" in
  DEEPSEEK) ENV_KEY="DEEPSEEK_API_KEY" ;;
  ANTHROPIC) ENV_KEY="ANTHROPIC_API_KEY" ;;
  GROQ) ENV_KEY="GROQ_API_KEY" ;;
  MISTRAL) ENV_KEY="MISTRAL_API_KEY" ;;
  KIMI|MOONSHOT) ENV_KEY="KIMI_API_KEY" ;;
  LITELLM) ENV_KEY="LITELLM_MASTER_KEY" ;;
esac

if [ ! -f .env ]; then
  echo "Error: .env file not found."
  exit 1
fi

# Check if the key exists in .env
if ! grep -q "^${ENV_KEY}=" .env 2>/dev/null; then
  echo "Error: Key '$ENV_KEY' not found in .env"
  echo "Available keys:"
  grep -v '^#' .env | grep -v '^$' | sed 's/=.*//' | while IFS= read -r key; do
    [ -n "$key" ] && echo "  - $key"
  done
  exit 1
fi

echo "=== Rotating $ENV_KEY ==="
echo ""
echo "Current value: $(grep "^${ENV_KEY}=" .env | sed 's/^[^=]*=//' | head -c 20)..."
echo ""

# Prompt for new key (read silently)
echo -n "Enter new API key for $PROVIDER: "
read -r NEW_KEY
echo ""

if [ -z "$NEW_KEY" ]; then
  echo "Error: No key entered. Aborting."
  exit 1
fi

# Update .env
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|^${ENV_KEY}=.*|${ENV_KEY}=${NEW_KEY}|" .env
else
  sed -i "s|^${ENV_KEY}=.*|${ENV_KEY}=${NEW_KEY}|" .env
fi

echo "✅ Updated $ENV_KEY in .env"
echo ""

# Restart the proxy if it's running
PORT="${PORT:-4000}"
if curl -sf "http://localhost:$PORT/health" > /dev/null 2>&1; then
  echo "Proxy is running. Restarting..."
  ./stop.sh 2>/dev/null || true
  sleep 1
  LITELLM_CONFIG="${LITELLM_CONFIG:-config.yaml}" PORT="$PORT" ./start.sh &
  echo "✅ Proxy restarted with new key."
else
  echo "Proxy is not running. Start it with: make start"
fi
