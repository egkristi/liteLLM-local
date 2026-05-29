#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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
source .env

# --- Port handling (ISSUE-3) ---
PORT="${PORT:-4000}"
if lsof -Pi ":$PORT" -sTCP:LISTEN -t &>/dev/null || netstat -an 2>/dev/null | grep -q ":$PORT .*LISTEN"; then
  echo "Warning: port $PORT is already in use. Set PORT to use a different one, e.g.:"
  echo "  PORT=4001 ./start.sh"
  exit 1
fi

mkdir -p logs

exec uv tool run litellm --config config.yaml --port "$PORT" 2>&1 | tee "logs/litellm-$(date +%Y%m%d-%H%M%S).log"
