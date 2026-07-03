#!/usr/bin/env bash
# Sync the LiteLLM Copilot Chat model list into VS Code's global User
# settings, so every project on this Mac uses the same (corrected) model
# definitions without needing its own .vscode/settings.json.
#
# Background: VS Code merges User and Workspace settings, but for a given
# key (like github.copilot.chat.languageModels) whichever scope is more
# specific wins outright -- there's no array merging. A per-project
# .vscode/settings.json with this key will still override the global one
# for that project. Remove those per-project overrides if you want the
# global config to be the single source of truth everywhere.
#
# Usage:
#   ./scripts/sync_global_vscode_settings.sh
#   make vscode-config-global

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOCAL_SETTINGS="$PROJECT_ROOT/.vscode/settings.json"

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

if [ ! -f "$LOCAL_SETTINGS" ]; then
  echo "Error: $LOCAL_SETTINGS not found. Run 'make vscode-config' first."
  exit 1
fi

# Candidate global VS Code User settings.json locations on macOS.
CANDIDATES=(
  "$HOME/Library/Application Support/Code/User/settings.json"
  "$HOME/Library/Application Support/Code - Insiders/User/settings.json"
)

FOUND_ANY=false

for GLOBAL_SETTINGS in "${CANDIDATES[@]}"; do
  if [ -f "$GLOBAL_SETTINGS" ]; then
    FOUND_ANY=true

    if ! jq empty "$GLOBAL_SETTINGS" 2>/dev/null; then
      echo "⚠️  Skipping $GLOBAL_SETTINGS -- not valid JSON (does it have comments/trailing commas?)"
      echo "    Strip those manually first, or merge the block below by hand."
      continue
    fi

    BACKUP="${GLOBAL_SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$GLOBAL_SETTINGS" "$BACKUP"

    MODELS_BLOCK=$(jq '.["github.copilot.chat.languageModels"]' "$LOCAL_SETTINGS")

    jq --argjson models "$MODELS_BLOCK" \
      '.["github.copilot.chat.languageModels"] = $models' \
      "$GLOBAL_SETTINGS" > "${GLOBAL_SETTINGS}.tmp" && mv "${GLOBAL_SETTINGS}.tmp" "$GLOBAL_SETTINGS"

    echo "✅ Updated: $GLOBAL_SETTINGS"
    echo "   Backup:  $BACKUP"
  fi
done

if [ "$FOUND_ANY" = false ]; then
  echo "No VS Code User settings.json found. Expected one of:"
  printf '  %s\n' "${CANDIDATES[@]}"
  echo "Open VS Code at least once, then re-run this script."
  exit 1
fi

echo ""
echo "Restart VS Code (or reload the window) to pick up the change."
echo "Reminder: any project's own .vscode/settings.json with this key still wins for that project."
