#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
  echo "Error: .env file not found. Create one from the README example."
  exit 1
fi

# shellcheck source=/dev/null
source .env

exec uv tool run litellm --config config.yaml --port 4000
