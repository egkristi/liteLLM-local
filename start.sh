#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Config profile support ---
# Set LITELLM_CONFIG to use a different config file, e.g.:
#   LITELLM_CONFIG=config.prod.yaml ./start.sh
CONFIG="${LITELLM_CONFIG:-config.yaml}"
if [ ! -f "$CONFIG" ]; then
  echo "Error: config file '$CONFIG' not found."
  echo "Set LITELLM_CONFIG to a valid config file, or use the default config.yaml."
  exit 1
fi
echo "Using config: $CONFIG"

# --- Prerequisite checks (ISSUE-2) ---
if ! command -v uv &>/dev/null; then
  echo "Error: 'uv' is not installed. Install it from https://docs.astral.sh/uv/"
  exit 1
fi

if ! uv tool list 2>/dev/null | grep -q litellm; then
  echo "Error: litellm is not installed as a uv tool. Run:"
  echo "  uv tool install 'litellm[proxy]'"
  exit 1
fi

if [ ! -f .env ]; then
  echo "Error: .env file not found. Create one from .env.example:"
  echo "  cp .env.example .env"
  exit 1
fi

# shellcheck source=/dev/null
set -a
source .env
set +a

# --- Port handling (ISSUE-3) ---
PORT="${PORT:-4000}"
if lsof -Pi ":$PORT" -sTCP:LISTEN -t &>/dev/null || netstat -an 2>/dev/null | grep -q ":$PORT .*LISTEN"; then
  echo "Warning: port $PORT is already in use. Set PORT to use a different one, e.g.:"
  echo "  PORT=4001 ./start.sh"
  exit 1
fi

mkdir -p logs

# --- Config reload / watch mode ---
RELOAD_FLAG=""
if [ "${LITELLM_RELOAD:-}" = "true" ]; then
  RELOAD_FLAG="--reload"
  echo "Config reload enabled (watches $CONFIG for changes)"
fi

exec uv tool run litellm --config "$CONFIG" --port "$PORT" $RELOAD_FLAG 2>&1 | tee "logs/litellm-$(date +%Y%m%d-%H%M%S).log"
