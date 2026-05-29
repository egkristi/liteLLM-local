#!/usr/bin/env bash
# Audit .env against .env.example.
# Checks for missing keys, placeholder values, and extra keys.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PASS=0
FAIL=0
WARN=0

pass() { PASS=$((PASS + 1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ❌ $1"; }
warn() { WARN=$((WARN + 1)); echo "  ⚠️  $1"; }

echo "=== liteLLM-local .env Audit ==="
echo ""

# --- Check files exist ---
if [ ! -f .env.example ]; then
  fail ".env.example not found"
  exit 1
fi
pass ".env.example exists"

if [ ! -f .env ]; then
  fail ".env not found (copy .env.example to .env and fill in your keys)"
  exit 1
fi
pass ".env exists"

# --- Parse keys from both files ---
get_keys() {
  grep -v '^#' "$1" | grep -v '^$' | sed 's/=.*//'
}

EXAMPLE_KEYS=$(get_keys .env.example)
ENV_KEYS=$(get_keys .env)

echo "--- Required keys from .env.example ---"
MISSING=0
PLACEHOLDER=0
while IFS= read -r key; do
  [ -z "$key" ] && continue
  if ! grep -q "^${key}=" .env 2>/dev/null; then
    fail "Missing key '$key' in .env"
    MISSING=1
  else
    val=$(grep "^${key}=" .env | sed 's/^[^=]*=//')
    if [ -z "$val" ]; then
      fail "Key '$key' is empty in .env"
      PLACEHOLDER=1
    elif [[ "$val" == *"..."* ]] || [[ "$val" == sk-...* ]] || [[ "$val" == gsk_...* ]]; then
      warn "Key '$key' still has placeholder value in .env"
      PLACEHOLDER=1
    else
      pass "Key '$key' is set"
    fi
  fi
done <<< "$EXAMPLE_KEYS"

echo ""
echo "--- Extra keys in .env (not in .env.example) ---"
EXTRA=0
while IFS= read -r key; do
  [ -z "$key" ] && continue
  if ! grep -q "^${key}=" .env.example 2>/dev/null; then
    warn "Extra key '$key' in .env (not in .env.example)"
    EXTRA=1
  fi
done <<< "$ENV_KEYS"
if [ "$EXTRA" -eq 0 ]; then
  pass "No extra keys in .env"
fi

echo ""
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"
if [ "$FAIL" -gt 0 ]; then
  echo "❌ Audit failed."
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "⚠️  Audit passed with warnings."
  exit 0
else
  echo "✅ Audit passed."
  exit 0
fi
