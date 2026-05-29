#!/usr/bin/env bash
# ===========================================================================
# uptime-monitor.sh — LiteLLM Local Uptime Monitor
# ===========================================================================
# Checks the proxy every N minutes and sends a macOS notification if it's
# down. Also logs uptime statistics to logs/uptime.csv.
#
# Usage:
#   ./uptime-monitor.sh              # Run once (check and exit)
#   ./uptime-monitor.sh --daemon     # Run continuously (every 5 min)
#   ./uptime-monitor.sh --install    # Install as a launchd agent
#   ./uptime-monitor.sh --uninstall  # Remove the launchd agent
#
# Options:
#   --interval MIN   Check interval in minutes (default: 5, min: 1)
#   --port PORT      Proxy port to check (default: 4000)
# ===========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
LOG_DIR="$PROJECT_DIR/logs"
INTERVAL=5
PORT="${PORT:-4000}"
MODE="once"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --daemon) MODE="daemon"; shift ;;
    --install) MODE="install"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Validate interval
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
  echo "Error: --interval must be a positive integer (minutes)"
  exit 1
fi

mkdir -p "$LOG_DIR"

notify() {
  local title="$1"
  local message="$2"
  osascript -e "display notification \"$message\" with title \"$title\" sound name \"Basso\"" 2>/dev/null || true
}

check_proxy() {
  local url="http://localhost:$PORT"
  local ts
  ts="$(date +%Y-%m-%dT%H:%M:%S%z)"

  if curl -sf "$url/health" --max-time 5 >/dev/null 2>&1; then
    echo "$ts,up" >> "$LOG_DIR/uptime.csv"
    return 0
  else
    echo "$ts,down" >> "$LOG_DIR/uptime.csv"
    notify "LiteLLM Proxy Down" "Proxy on port $PORT is not responding. Check with: make status"
    return 1
  fi
}

# --- Install as launchd agent ---
if [ "$MODE" = "install" ]; then
  PLIST_LABEL="com.litellm-local.uptime-monitor"
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
    <string>$PROJECT_DIR/uptime-monitor.sh</string>
    <string>--daemon</string>
    <string>--interval</string>
    <string>$INTERVAL</string>
    <string>--port</string>
    <string>$PORT</string>
  </array>
  <key>StartInterval</key>
  <integer>$((INTERVAL * 60))</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/uptime-monitor.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/uptime-monitor.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/usr/bin:/bin:$PATH</string>
  </dict>
</dict>
</plist>
EOF

  launchctl load "$PLIST_PATH"
  echo "✅ Uptime monitor installed as launchd agent (every ${INTERVAL}min)"
  echo "   Plist: $PLIST_PATH"
  echo "   Log:   $LOG_DIR/uptime-monitor.log"
  echo "   Data:  $LOG_DIR/uptime.csv"
  exit 0
fi

# --- Uninstall ---
if [ "$MODE" = "uninstall" ]; then
  PLIST_LABEL="com.litellm-local.uptime-monitor"
  PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

  if [ -f "$PLIST_PATH" ]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm "$PLIST_PATH"
    echo "✅ Uptime monitor uninstalled"
  else
    echo "Uptime monitor is not installed"
  fi
  exit 0
fi

# --- Daemon mode ---
if [ "$MODE" = "daemon" ]; then
  echo "Uptime monitor started (interval: ${INTERVAL}min, port: $PORT)"
  echo "Log: $LOG_DIR/uptime-monitor.log"
  echo "Data: $LOG_DIR/uptime.csv"
  while true; do
    check_proxy
    sleep $((INTERVAL * 60))
  done
fi

# --- Once mode (default) ---
check_proxy
echo "Uptime data logged to $LOG_DIR/uptime.csv"
