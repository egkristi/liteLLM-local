#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-4000}"
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
