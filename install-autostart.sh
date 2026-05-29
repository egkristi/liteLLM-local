#!/usr/bin/env bash
# Install a launchd plist to auto-start the LiteLLM proxy on login.
# Usage: ./install-autostart.sh [--uninstall]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PLIST_NAME="com.litellm.proxy"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_NAME}.plist"
LOG_DIR="$SCRIPT_DIR/logs"

# Resolve the repo path to a real path (no symlinks)
REPO_PATH=$(cd "$SCRIPT_DIR" && pwd -P)

# Determine the Python wrapper path
WRAPPER="$REPO_PATH/litellm-local"
if [ ! -f "$WRAPPER" ]; then
  echo "Error: litellm-local wrapper not found at $WRAPPER"
  exit 1
fi

# Find the uv tool runner
UV_RUNNER=$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")
if [ ! -x "$UV_RUNNER" ]; then
  echo "Error: 'uv' not found. Install it from https://docs.astral.sh/uv/"
  exit 1
fi

uninstall() {
  echo "=== Uninstalling autostart ==="
  if [ -f "$PLIST_PATH" ]; then
    launchctl bootout "gui/$(id -u)/${PLIST_NAME}" 2>/dev/null || true
    rm -f "$PLIST_PATH"
    echo "✅ Removed $PLIST_PATH"
  else
    echo "No plist found at $PLIST_PATH"
  fi
  exit 0
}

if [ "${1:-}" = "--uninstall" ]; then
  uninstall
fi

echo "=== Installing LiteLLM Proxy Autostart ==="
echo "Repo path: $REPO_PATH"
echo "Wrapper: $WRAPPER"
echo "Plist: $PLIST_PATH"
echo ""

mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$PLIST_PATH")"

cat > "$PLIST_PATH" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>

    <key>ProgramArguments</key>
    <array>
        <string>${UV_RUNNER}</string>
        <string>tool</string>
        <string>run</string>
        <string>litellm</string>
        <string>--config</string>
        <string>${REPO_PATH}/config.yaml</string>
        <string>--port</string>
        <string>4000</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${REPO_PATH}</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${PATH}</string>
        <key>HOME</key>
        <string>${HOME}</string>
    </dict>

    <key>StandardOutPath</key>
    <string>${LOG_DIR}/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/launchd-stderr.log</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>ThrottleInterval</key>
    <integer>5</integer>
</dict>
</plist>
PLIST

echo "✅ Plist written to $PLIST_PATH"
echo ""

# Load the plist
echo "Loading launchd plist..."
if launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH" 2>/dev/null; then
  echo "✅ Autostart installed and loaded."
elif launchctl print "gui/$(id -u)/${PLIST_NAME}" >/dev/null 2>&1; then
  echo "✅ Autostart already loaded."
else
  echo "⚠️  Could not bootstrap plist. You may need to log out and back in."
  echo "   Or load manually: launchctl bootstrap gui/$(id -u) $PLIST_PATH"
fi

echo ""
echo "=== Next steps ==="
echo "  - The proxy will start automatically on login."
echo "  - To start now: launchctl kickstart gui/$(id -u)/${PLIST_NAME}"
echo "  - To stop: launchctl bootout gui/$(id -u)/${PLIST_NAME}"
echo "  - To uninstall: $0 --uninstall"
echo "  - Logs: $LOG_DIR/launchd-stdout.log"
