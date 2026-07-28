#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-4000}"
CACHE_PORT="${LITELLM_CACHE_PORT:-4001}"
SANITIZE_PORT="${LITELLM_SANITIZE_PORT:-4002}"

# Stop sanitize proxy (if running)
SANITIZE_PID=$(lsof -Pi ":$SANITIZE_PORT" -sTCP:LISTEN -t 2>/dev/null || true)
if [ -n "$SANITIZE_PID" ]; then
  echo "Stopping sanitize proxy on port $SANITIZE_PORT (PID $SANITIZE_PID)..."
  kill "$SANITIZE_PID" 2>/dev/null || true
fi

# Stop cache proxy (if running)
CACHE_PID=$(lsof -Pi ":$CACHE_PORT" -sTCP:LISTEN -t 2>/dev/null || true)
if [ -n "$CACHE_PID" ]; then
  echo "Stopping cache proxy on port $CACHE_PORT (PID $CACHE_PID)..."
  kill "$CACHE_PID" 2>/dev/null || true
fi

# Stop LiteLLM proxy
PID=$(lsof -Pi ":$PORT" -sTCP:LISTEN -t 2>/dev/null || true)
if [ -z "$PID" ]; then
  echo "No LiteLLM proxy found on port $PORT."
  exit 0
fi

echo "Stopping LiteLLM proxy on port $PORT (PID $PID)..."
kill "$PID"

# Wait up to 5 seconds for graceful shutdown
for _ in {1..5}; do
  if ! kill -0 "$PID" 2>/dev/null; then
    echo "Stopped."
    exit 0
  fi
  sleep 1
done

echo "Force killing PID $PID..."
kill -9 "$PID" 2>/dev/null || true
echo "Stopped."
