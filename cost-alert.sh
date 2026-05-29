#!/usr/bin/env bash
# ===========================================================================
# cost-alert.sh — LiteLLM Local Cost Alert
# ===========================================================================
# Checks estimated monthly spend from proxy logs and sends a macOS
# notification if it exceeds a threshold.
#
# Usage:
#   ./cost-alert.sh                          # Check and notify if over $20
#   ./cost-alert.sh --threshold 50           # Alert at $50
#   ./cost-alert.sh --threshold 50 --monthly # Alert at $50/month
#   ./cost-alert.sh --install                # Install as daily launchd agent
#   ./cost-alert.sh --uninstall              # Remove launchd agent
# ===========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
THRESHOLD=20
MODE="once"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold) THRESHOLD="$2"; shift 2 ;;
    --install) MODE="install"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if ! [[ "$THRESHOLD" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "Error: --threshold must be a number"
  exit 1
fi

notify() {
  local title="$1"
  local message="$2"
  osascript -e "display notification \"$message\" with title \"$title\" sound name \"Basso\"" 2>/dev/null || true
}

estimate_spend() {
  local total=0
  local count=0

  # Parse cost lines from logs
  # LiteLLM logs cost as: cost=$X.XX or "cost": X.XX
  while IFS= read -r line; do
    local cost_val
    cost_val=$(echo "$line" | grep -oE 'cost=\$?[0-9]+\.[0-9]+' | sed 's/cost=\$//' || true)
    if [ -z "$cost_val" ]; then
      cost_val=$(echo "$line" | grep -oE '"cost":\s*[0-9]+\.[0-9]+' | sed 's/"cost":\s*//' || true)
    fi
    if [ -n "$cost_val" ]; then
      total=$(echo "$total + $cost_val" | bc 2>/dev/null || echo "$total")
      count=$((count + 1))
    fi
  done < <(cat "$LOG_DIR"/*.log 2>/dev/null || true)

  # Estimate monthly: if we have data, extrapolate from the date range
  local first_date last_date days_elapsed monthly_est
  first_date=$(head -n 1 "$LOG_DIR"/*.log 2>/dev/null | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "")
  last_date=$(tail -n 1 "$LOG_DIR"/*.log 2>/dev/null | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "")

  if [ -n "$first_date" ] && [ -n "$last_date" ] && [ "$total" != "0" ]; then
    local sec1 sec2 diff_days
    sec1=$(date -j -f "%Y-%m-%d" "$first_date" "+%s" 2>/dev/null || echo 0)
    sec2=$(date -j -f "%Y-%m-%d" "$last_date" "+%s" 2>/dev/null || echo 0)
    diff_days=$(( (sec2 - sec1) / 86400 ))
    if [ "$diff_days" -gt 0 ]; then
      monthly_est=$(echo "scale=2; $total / $diff_days * 30" | bc)
    else
      monthly_est=$total
    fi
  else
    monthly_est=$total
  fi

  echo "$total|$monthly_est|$count"
}

# --- Install as daily launchd agent ---
if [ "$MODE" = "install" ]; then
  PLIST_LABEL="com.litellm-local.cost-alert"
  PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

  mkdir -p "$HOME/Library/LaunchAgents"

  cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$PLIST_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$SCRIPT_DIR/cost-alert.sh</string>
    <string>--threshold</string>
    <string>$THRESHOLD</string>
  </array>
  <key>StartInterval</key>
  <integer>86400</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/cost-alert.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/cost-alert.log</string>
</dict>
</plist>
EOF

  launchctl load "$PLIST_PATH"
  echo "✅ Cost alert installed (daily check, threshold: \$${THRESHOLD})"
  echo "   Plist: $PLIST_PATH"
  exit 0
fi

# --- Uninstall ---
if [ "$MODE" = "uninstall" ]; then
  PLIST_LABEL="com.litellm-local.cost-alert"
  PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

  if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm "$PLIST_PATH"
    echo "✅ Cost alert uninstalled"
  else
    echo "Cost alert is not installed"
  fi
  exit 0
fi

# --- Once mode (default) ---
if [ ! -d "$LOG_DIR" ] || [ -z "$(ls -A "$LOG_DIR"/*.log 2>/dev/null)" ]; then
  echo "No log files found. Start the proxy first."
  exit 0
fi

DATA=$(estimate_spend)
TOTAL=$(echo "$DATA" | cut -d'|' -f1)
MONTHLY=$(echo "$DATA" | cut -d'|' -f2)
COUNT=$(echo "$DATA" | cut -d'|' -f3)

echo "=== Cost Summary ==="
echo "  Total spend:    \$${TOTAL:-0}"
echo "  Est. monthly:   \$${MONTHLY:-0}"
echo "  Cost entries:   ${COUNT:-0}"
echo "  Alert threshold: \$${THRESHOLD}"

if [ "$(echo "$MONTHLY > $THRESHOLD" | bc 2>/dev/null)" = "1" ]; then
  notify "LiteLLM Cost Alert" "Estimated monthly spend \$${MONTHLY} exceeds \$${THRESHOLD} threshold"
  echo "⚠️  Alert sent: monthly spend exceeds threshold"
else
  echo "✅ Under threshold (\$${MONTHLY:-0} / \$${THRESHOLD})"
fi
