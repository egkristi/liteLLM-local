#!/usr/bin/env bash
# Install autostart for LiteLLM Proxy.
#   - Linux:   systemd service
#   - macOS:   launchd plist
#
# Usage: ./install-autostart.sh [--uninstall] [--user]
#   --uninstall   Remove the autostart configuration
#   --user        Install as user service (Linux only, systemd --user)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Resolve the repo path to a real path (no symlinks)
REPO_PATH=$(cd "$SCRIPT_DIR" && pwd -P)
LOG_DIR="$REPO_PATH/logs"

# Detect platform
OS="$(uname -s)"

# Parse flags
UNINSTALL=false
USER_MODE=false
for arg in "$@"; do
  case "$arg" in
    --uninstall) UNINSTALL=true ;;
    --user) USER_MODE=true ;;
  esac
done

# ─── macOS (launchd) ────────────────────────────────────────────────────────

macos_install() {
  local plist_name="com.litellm.proxy"
  local plist_path="$HOME/Library/LaunchAgents/${plist_name}.plist"

  # Find the uv tool runner
  local uv_runner
  uv_runner=$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")
  if [ ! -x "$uv_runner" ]; then
    echo "Error: 'uv' not found. Install it from https://docs.astral.sh/uv/"
    exit 1
  fi

  mkdir -p "$LOG_DIR"
  mkdir -p "$(dirname "$plist_path")"

  # Read .env file and build environment variables dict for launchd
  local env_dict=""
  if [ -f "$REPO_PATH/.env" ]; then
    while IFS='=' read -r key value || [ -n "$key" ]; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      value="${value%\"}"
      value="${value#\"}"
      env_dict="${env_dict}        <key>${key}</key>
        <string>${value}</string>
"
    done < "$REPO_PATH/.env"
  fi

  cat > "$plist_path" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${plist_name}</string>

    <key>ProgramArguments</key>
    <array>
        <string>${uv_runner}</string>
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
${env_dict}    </dict>

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

  echo "✅ Plist written to $plist_path"

  # Load the plist
  echo "Loading launchd plist..."
  if launchctl bootstrap "gui/$(id -u)" "$plist_path" 2>/dev/null; then
    echo "✅ Autostart installed and loaded."
  elif launchctl print "gui/$(id -u)/${plist_name}" >/dev/null 2>&1; then
    echo "✅ Autostart already loaded."
  else
    echo "⚠️  Could not bootstrap plist. You may need to log out and back in."
    echo "   Or load manually: launchctl bootstrap gui/$(id -u) $plist_path"
  fi
}

macos_uninstall() {
  local plist_name="com.litellm.proxy"
  local plist_path="$HOME/Library/LaunchAgents/${plist_name}.plist"

  echo "=== Uninstalling autostart (macOS) ==="
  if [ -f "$plist_path" ]; then
    launchctl bootout "gui/$(id -u)/${plist_name}" 2>/dev/null || true
    rm -f "$plist_path"
    echo "✅ Removed $plist_path"
  else
    echo "No plist found at $plist_path"
  fi
}

# ─── Linux (systemd) ────────────────────────────────────────────────────────

linux_install() {
  local service_name="litellm-proxy"
  local service_src="$REPO_PATH/${service_name}.service"
  local service_dst=""

  if [ "$USER_MODE" = true ]; then
    service_dst="$HOME/.config/systemd/user/${service_name}.service"
    mkdir -p "$(dirname "$service_dst")"
  else
    service_dst="/etc/systemd/system/${service_name}.service"
  fi

  if [ ! -f "$service_src" ]; then
    echo "Error: service file not found at $service_src"
    exit 1
  fi

  echo "=== Installing LiteLLM Proxy Autostart (Linux systemd) ==="
  echo "Repo path: $REPO_PATH"
  echo "Service: $service_dst"
  echo ""

  # Copy the service file, fixing paths to match the actual repo path
  if [ "$USER_MODE" = true ]; then
    sed "s|/home/erling/code/liteLLM-local|$REPO_PATH|g" "$service_src" > "$service_dst"
    # Relax security hardening for user services
    sed -i 's/^ProtectHome=read-only/# ProtectHome=read-only (relaxed for user service)/' "$service_dst" 2>/dev/null || true
    sed -i 's/^ProtectSystem=strict/# ProtectSystem=strict (relaxed for user service)/' "$service_dst" 2>/dev/null || true
    echo "✅ Copied to $service_dst (user service)"
  else
    if [ "$(id -u)" -ne 0 ]; then
      sed "s|/home/erling/code/liteLLM-local|$REPO_PATH|g" "$service_src" | sudo tee "$service_dst" > /dev/null
    else
      sed "s|/home/erling/code/liteLLM-local|$REPO_PATH|g" "$service_src" > "$service_dst"
    fi
    echo "✅ Copied to $service_dst (system service)"
  fi

  # Reload systemd, enable, and start
  if [ "$USER_MODE" = true ]; then
    systemctl --user daemon-reload
    systemctl --user enable "$service_name"
    systemctl --user start "$service_name" || echo "⚠️  Could not start service. Check 'systemctl --user status $service_name'"
  else
    local sudo_cmd=""
    [ "$(id -u)" -ne 0 ] && sudo_cmd="sudo"
    $sudo_cmd systemctl daemon-reload
    $sudo_cmd systemctl enable "$service_name"
    $sudo_cmd systemctl start "$service_name" || echo "⚠️  Could not start service. Check '${sudo_cmd} systemctl status $service_name'"
  fi

  echo ""
  echo "=== Next steps ==="
  echo "  - Status:  systemctl $([ "$USER_MODE" = true ] && echo '--user ')status $service_name"
  echo "  - Start:   systemctl $([ "$USER_MODE" = true ] && echo '--user ')start $service_name"
  echo "  - Stop:    systemctl $([ "$USER_MODE" = true ] && echo '--user ')stop $service_name"
  echo "  - Logs:    journalctl $([ "$USER_MODE" = true ] && echo '--user ') -u $service_name -f"
  echo "  - Reload:  systemctl $([ "$USER_MODE" = true ] && echo '--user ')daemon-reload"
  echo "  - Uninstall: $0 --uninstall"
  echo "  - Log dir: $LOG_DIR"
}

linux_uninstall() {
  local service_name="litellm-proxy"

  echo "=== Uninstalling autostart (Linux) ==="

  if [ "$USER_MODE" = true ]; then
    local service_path="$HOME/.config/systemd/user/${service_name}.service"
    if [ -f "$service_path" ]; then
      systemctl --user stop "$service_name" 2>/dev/null || true
      systemctl --user disable "$service_name" 2>/dev/null || true
      rm -f "$service_path"
      systemctl --user daemon-reload
      echo "✅ Removed $service_path"
    else
      echo "No service file found at $service_path"
    fi
  else
    local service_path="/etc/systemd/system/${service_name}.service"
    if [ -f "$service_path" ]; then
      local sudo_cmd=""
      [ "$(id -u)" -ne 0 ] && sudo_cmd="sudo"
      $sudo_cmd systemctl stop "$service_name" 2>/dev/null || true
      $sudo_cmd systemctl disable "$service_name" 2>/dev/null || true
      $sudo_cmd rm -f "$service_path"
      $sudo_cmd systemctl daemon-reload
      echo "✅ Removed $service_path"
    else
      echo "No service file found at $service_path"
    fi
  fi
}

# ─── Main ───────────────────────────────────────────────────────────────────

case "$OS" in
  Darwin)
    if [ "$UNINSTALL" = true ]; then
      macos_uninstall
    else
      macos_install
    fi
    ;;
  Linux)
    if [ "$UNINSTALL" = true ]; then
      linux_uninstall
    else
      linux_install
    fi
    ;;
  *)
    echo "Error: unsupported platform '$OS'. This script supports macOS and Linux."
    exit 1
    ;;
esac
