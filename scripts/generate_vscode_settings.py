#!/usr/bin/env python3
"""Regenerate .vscode/settings.json from config.yaml.

Reads the model_list from config.yaml and generates VS Code Copilot Chat
language model entries so the two never drift out of sync.

Usage:
  python3 scripts/generate_vscode_settings.py
  make vscode-config
"""

import json
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = PROJECT_ROOT / "config.yaml"
VSCODE_SETTINGS_PATH = PROJECT_ROOT / ".vscode" / "settings.json"


def parse_config(config_path: Path):
    """Parse model_list from config.yaml and return list of model entries."""
    if not config_path.exists():
        print(f"Error: {config_path} not found")
        sys.exit(1)

    content = config_path.read_text()

    # Find all top-level model entries (2-space indented model_name:)
    # Pattern: capture everything between "- model_name:" and the next "- model_name:" or end
    model_entries = []
    pattern = r'^  - model_name:\s+(\S+)\s*\n((?:  (?!- model_name:).*\n?)*)'
    for match in re.finditer(pattern, content, re.MULTILINE):
        name = match.group(1)
        block = match.group(2)

        # Determine a nice display name
        display_name = name.replace('-', ' ').replace('_', ' ').title()
        # Special cases
        name_lower = name.lower()
        if 'deepseek' in name_lower:
            display_name = name.replace('-', ' ').title().replace('V4', 'V4')
        if 'qwen' in name_lower:
            display_name = name.replace('-', ' ').title()
        if 'kimi' in name_lower:
            display_name = name.replace('-', ' ').title()
        if 'ministral' in name_lower:
            display_name = name.replace('-', ' ').title()
        if 'nomic' in name_lower:
            display_name = "Nomic Embed"

        model_entries.append({
            "name": name,
            "display": f"LiteLLM {display_name}",
        })

    return model_entries


def generate_settings(model_entries):
    """Generate the VS Code settings JSON."""
    # First entry is active (uncommented), rest are commented out
    settings = {
        "github.copilot.chat.languageModels": []
    }

    for i, entry in enumerate(model_entries):
        model_obj = {
            "name": entry["display"],
            "vendor": "openai",
            "url": "http://localhost:4000/v1",
            "apiKey": "anything",
            "model": entry["name"],
        }

        if i == 0:
            # First model is active
            settings["github.copilot.chat.languageModels"].append(model_obj)
        else:
            # Commented out
            settings["github.copilot.chat.languageModels"].append(
                f"// {json.dumps(model_obj)}"
            )

    return settings


def write_settings(settings, output_path: Path):
    """Write settings to .vscode/settings.json."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Build the JSON manually for clean formatting with comments
    lines = ["{"]
    lines.append('  "github.copilot.chat.languageModels": [')
    models = settings["github.copilot.chat.languageModels"]
    for i, model in enumerate(models):
        comma = "," if i < len(models) - 1 else ""
        if isinstance(model, str) and model.startswith("// "):
            # Commented entry
            obj_str = model[3:]  # strip "// "
            lines.append(f"    // {obj_str}{comma}")
        else:
            obj_str = json.dumps(model, indent=4)
            obj_lines = obj_str.split("\n")
            for j, line in enumerate(obj_lines):
                prefix = "    " if j > 0 else "    "
                lines.append(f"{prefix}{line}")
            lines[-1] = f"{lines[-1]}{comma}"
    lines.append("  ]")
    lines.append("}")

    output_path.write_text("\n".join(lines) + "\n")
    print(f"✅ Generated {output_path}")
    print(f"   Models: {len(models)} ({models[0]['model']} active, {len(models)-1} commented)")


def main():
    model_entries = parse_config(CONFIG_PATH)
    if not model_entries:
        print("Error: no model entries found in config.yaml")
        sys.exit(1)

    settings = generate_settings(model_entries)
    write_settings(settings, VSCODE_SETTINGS_PATH)


if __name__ == "__main__":
    main()
