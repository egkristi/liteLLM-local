#!/usr/bin/env bash
# Validate the liteLLM-local setup.
# Checks:
#   1. .env file exists and has all required keys
#   2. Config file is valid YAML (via litellm-local config)
#   3. All referenced env vars are set (not placeholder values)
#   4. Proxy is reachable (if running)
#   5. Each model's provider has its API key set
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CONFIG="${LITELLM_CONFIG:-config.yaml}"
PASS=0
FAIL=0
WARN=0

pass() { PASS=$((PASS + 1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ❌ $1"; }
warn() { WARN=$((WARN + 1)); echo "  ⚠️  $1"; }

echo "=== liteLLM-local Validation ==="
echo "Config file: $CONFIG"
echo ""

# --- 1. Check .env file ---
echo "--- Environment ---"
if [ ! -f .env ]; then
  fail ".env file not found (copy .env.example to .env)"
else
  pass ".env file exists"

  # shellcheck source=/dev/null
  set -a
  source .env
  set +a

  # Extract all env var references from config
  ENV_REFS=$(grep -oP 'os\.environ/\K[A-Z_]+' "$CONFIG" 2>/dev/null || true)
  if [ -z "$ENV_REFS" ]; then
    warn "No env var references found in $CONFIG"
  else
    for ref in $ENV_REFS; do
      val="${!ref:-}"
      if [ -z "$val" ]; then
        fail "Env var '$ref' is not set in .env"
      elif [[ "$val" == *"..."* ]] || [[ "$val" == sk-...* ]] || [[ "$val" == gsk_...* ]]; then
        fail "Env var '$ref' still has placeholder value in .env"
      else
        pass "Env var '$ref' is set"
      fi
    done
  fi
fi
echo ""

# --- 2. Validate config file ---
echo "--- Configuration ---"
if python3 "$SCRIPT_DIR/litellm-local" config --config "$CONFIG" 2>&1; then
  pass "Config file is valid"
else
  fail "Config file has errors"
fi
echo ""

# --- 3. Check proxy reachability ---
echo "--- Proxy Health ---"
PORT="${PORT:-4000}"
if curl -sf "http://localhost:$PORT/health" > /dev/null 2>&1; then
  pass "Proxy is running on port $PORT"
  # List available models
  MODELS=$(curl -sf "http://localhost:$PORT/v1/models" 2>/dev/null | python3 -c "import sys,json; data=json.load(sys.stdin); print('\n'.join(m['id'] for m in data.get('data',[])))" 2>/dev/null || true)
  if [ -n "$MODELS" ]; then
    echo "     Available models:"
    echo "$MODELS" | while IFS= read -r m; do echo "       - $m"; done
  fi
else
  warn "Proxy is not running (start with: make start)"
fi
echo ""

# --- Summary ---
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"
if [ "$FAIL" -gt 0 ]; then
  echo "❌ Some checks failed."
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "⚠️  All checks passed with warnings."
  exit 0
else
  echo "✅ All checks passed."
  exit 0
fi
