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

# Try jq-based JSON parsing first (for json_logs=true), fall back to grep
if command -v jq &>/dev/null; then
  # Parse JSON log lines for usage/cost fields
  found=false
  for logfile in "$LOG_DIR"/*.log; do
    [ -f "$logfile" ] || continue
    while IFS= read -r line; do
      # Only process JSON lines
      if echo "$line" | jq -e '.usage | has("prompt_tokens") or has("completion_tokens") or has("cost")' &>/dev/null 2>/dev/null; then
        echo "$line" | jq -r '{prompt_tokens: (.usage.prompt_tokens // 0), completion_tokens: (.usage.completion_tokens // 0), total_tokens: (.usage.total_tokens // 0), cost: (.cost // 0)} | "tokens_in=\(.prompt_tokens) tokens_out=\(.completion_tokens) total=\(.total_tokens) cost=$\(.cost)"' 2>/dev/null
        found=true
      fi
    done < "$logfile"
  done
  if [ "$found" = false ]; then
    echo "No usage data found in JSON logs."
  fi
else
  # Fallback: grep-based parsing for non-JSON logs
  grep -h "completion_tokens\|prompt_tokens\|cost" "$LOG_DIR"/*.log 2>/dev/null | tail -n 20 || echo "No usage data in logs yet."
fi
