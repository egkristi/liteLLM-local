#!/usr/bin/env bash
# ===========================================================================
# export-spend.sh — Export daily spend to CSV
# ===========================================================================
# Parses LiteLLM proxy logs and exports a CSV with daily spend breakdown
# by model. Useful for analysis in Excel, Numbers, or Google Sheets.
#
# Usage:
#   ./export-spend.sh                    # Export all-time spend
#   ./export-spend.sh --days 7           # Last 7 days only
#   ./export-spend.sh --days 30 --model  # Breakdown by model
#   ./export-spend.sh --output spend.csv # Write to specific file
# ===========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
DAYS=0
BY_MODEL=false
OUTPUT=""

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --days) DAYS="$2"; shift 2 ;;
    --model) BY_MODEL=true; shift ;;
    --output) OUTPUT="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ ! -d "$LOG_DIR" ] || [ -z "$(ls -A "$LOG_DIR"/*.log 2>/dev/null)" ]; then
  echo "No log files found in $LOG_DIR"
  echo "Start the proxy first: ./start.sh"
  exit 1
fi

# Determine cutoff date
CUTOFF=""
if [ "$DAYS" -gt 0 ]; then
  CUTOFF=$(date -v-${DAYS}d "+%Y-%m-%d" 2>/dev/null || date -d "-${DAYS} days" "+%Y-%m-%d" 2>/dev/null || echo "")
fi

# Collect log files
LOG_FILES=("$LOG_DIR"/*.log)
if [ ${#LOG_FILES[@]} -eq 0 ]; then
  echo "No log files found"
  exit 1
fi

# Build the CSV
if [ "$BY_MODEL" = true ]; then
  # Per-model breakdown
  if [ -n "$OUTPUT" ]; then
    exec > "$OUTPUT"
  fi
  echo "date,model,cost,tokens,total_requests"

  for logfile in "$LOG_DIR"/*.log; do
    # Extract date from filename (litellm-YYYYMMDD-HHMMSS.log)
    filename=$(basename "$logfile")
    filedate=""
    if [[ "$filename" =~ litellm-([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
      filedate="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    fi

    # Skip if outside date range
    if [ -n "$CUTOFF" ] && [ -n "$filedate" ]; then
      if [[ "$filedate" < "$CUTOFF" ]]; then
        continue
      fi
    fi

    # Parse each line for cost and model info
    while IFS= read -r line; do
      local cost model tokens
      cost=$(echo "$line" | grep -oE 'cost=\$?[0-9]+\.[0-9]+' | sed 's/cost=\$//' | head -1 || echo "")
      if [ -z "$cost" ]; then
        cost=$(echo "$line" | grep -oE '"cost":\s*[0-9]+\.[0-9]+' | sed 's/"cost":\s*//' | head -1 || echo "")
      fi
      model=$(echo "$line" | grep -oE 'model=[^ ]+' | head -1 | sed 's/model=//' || echo "unknown")
      tokens=$(echo "$line" | grep -oE 'total_tokens=[0-9]+' | sed 's/total_tokens=//' | head -1 || echo "0")

      if [ -n "$cost" ]; then
        echo "${filedate:-unknown},${model},${cost},${tokens:-0},1"
      fi
    done < "$logfile"
  done

else
  # Daily summary
  if [ -n "$OUTPUT" ]; then
    exec > "$OUTPUT"
  fi
  echo "date,total_cost,total_tokens,total_requests"

  # Aggregate by date
  declare -A date_cost date_tokens date_count

  for logfile in "$LOG_DIR"/*.log; do
    filename=$(basename "$logfile")
    filedate=""
    if [[ "$filename" =~ litellm-([0-9]{4})([0-9]{2})([0-9]{2}) ]]; then
      filedate="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
    fi
    [ -z "$filedate" ] && filedate="unknown"

    # Skip if outside date range
    if [ -n "$CUTOFF" ] && [ "$filedate" != "unknown" ]; then
      if [[ "$filedate" < "$CUTOFF" ]]; then
        continue
      fi
    fi

    while IFS= read -r line; do
      local cost tokens
      cost=$(echo "$line" | grep -oE 'cost=\$?[0-9]+\.[0-9]+' | sed 's/cost=\$//' | head -1 || echo "")
      if [ -z "$cost" ]; then
        cost=$(echo "$line" | grep -oE '"cost":\s*[0-9]+\.[0-9]+' | sed 's/"cost":\s*//' | head -1 || echo "")
      fi
      tokens=$(echo "$line" | grep -oE 'total_tokens=[0-9]+' | sed 's/total_tokens=//' | head -1 || echo "0")

      if [ -n "$cost" ]; then
        date_cost["$filedate"]=$(echo "${date_cost[$filedate]:-0} + $cost" | bc 2>/dev/null || echo "${date_cost[$filedate]:-0}")
        date_tokens["$filedate"]=$((date_tokens["$filedate"] + tokens))
        date_count["$filedate"]=$((date_count["$filedate"] + 1))
      fi
    done < "$logfile"
  done

  # Output sorted by date
  for date in $(echo "${!date_cost[@]}" | tr ' ' '\n' | sort); do
    echo "${date},${date_cost[$date]},${date_tokens[$date]:-0},${date_count[$date]:-0}"
  done
fi

if [ -n "$OUTPUT" ]; then
  echo "✅ Spend data exported to: $OUTPUT"
fi
