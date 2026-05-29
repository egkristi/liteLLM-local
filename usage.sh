#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"

if [ ! -d "$LOG_DIR" ]; then
  echo "No logs directory found. Start the proxy first."
  exit 1
fi

echo "=== LiteLLM Recent Logs ==="
tail -n 50 "$LOG_DIR"/*.log 2>/dev/null || echo "No log files yet."

echo ""
echo "=== Estimated Usage (from log parsing) ==="
grep -h "completion_tokens\|prompt_tokens\|cost" "$LOG_DIR"/*.log 2>/dev/null | tail -n 20 || echo "No usage data in logs yet."
