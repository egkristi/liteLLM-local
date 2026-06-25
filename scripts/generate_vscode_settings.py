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


def _model_capabilities(name: str, block: str) -> dict:
    """Determine model capabilities based on model name and config block."""
    name_lower = name.lower()

    # Vision capability
    vision = any(kw in name_lower for kw in ['vl-', 'vision', 'gemini', 'kimi', 'minimax', 'mistral-large', 'claude-sonnet', 'claude-opus'])

    # Tool calling
    tool_calling = 'nomic-embed' not in name_lower

    # Token limits
    if 'codestral' in name_lower:
        max_input = 256000
    elif 'claude' in name_lower:
        max_input = 200000
    elif 'nomic-embed' in name_lower:
        max_input = 8192
    else:
        max_input = 128000

    if 'nomic-embed' in name_lower:
        max_output = 1
    elif 'groq-llama' in name_lower:
        max_output = 8000
    else:
        max_output = 16000

    return {
        "toolCalling": tool_calling,
        "vision": vision,
        "maxInputTokens": max_input,
        "maxOutputTokens": max_output,
    }


def _friendly_name(name: str) -> str:
    """Map model IDs to friendly display names."""
    names = {
        "deepseek-v4-pro": "DeepSeek V4 Pro",
        "claude-sonnet": "Claude Sonnet 4.6",
        "claude-opus": "Claude Opus 4.8",
        "groq-llama": "Groq Llama 4 Maverick",
        "mistral-large": "Mistral Medium 3.5",
        "codestral": "Codestral 25.08",
        "kimi-latest": "Kimi K2.6",
        "deepseek-local": "DeepSeek V4 (local)",
        "qwen2.5-coder": "Qwen2.5 Coder (local)",
        "deepseek-v4-pro-cloud": "DeepSeek V4 Pro (cloud)",
        "deepseek-v4-flash-cloud": "DeepSeek V4 Flash (cloud)",
        "gemma4-31b-cloud": "Gemma 4 31B (cloud)",
        "gemini-3-flash-cloud": "Gemini 3 Flash (cloud)",
        "glm-5.1-cloud": "GLM 5.1 (cloud)",
        "kimi-k2.5-cloud": "Kimi K2.5 (cloud)",
        "kimi-k2.6-cloud": "Kimi K2.6 (cloud)",
        "kimi-k2.7-code-cloud": "Kimi K2.7 Code (cloud)",
        "minimax-m2.7-cloud": "MiniMax M2.7 (cloud)",
        "ministral-3-3b-cloud": "Ministral 3 3B (cloud)",
        "ministral-3-8b-cloud": "Ministral 3 8B (cloud)",
        "ministral-3-14b-cloud": "Ministral 3 14B (cloud)",
        "mistral-large-3-675b-cloud": "Mistral Large 3 675B (cloud)",
        "qwen3.5-397b-cloud": "Qwen 3.5 397B (cloud)",
        "qwen3-vl-235b-cloud": "Qwen3 VL 235B (cloud)",
        "qwen3-vl-235b-instruct-cloud": "Qwen3 VL 235B Instruct (cloud)",
        "nomic-embed-text": "Nomic Embed Text",
        "fallback-deepseek": "Fallback Chain (DeepSeek → Claude → Groq)",
        "best-coding": "⭐ Best Coding → DeepSeek V4 Pro",
        "best-chat": "⭐ Best Chat → Claude Sonnet 4.6",
        "fast": "⭐ Fast → Groq Llama 4 Maverick",
        "cheap": "⭐ Cheap → DeepSeek V4 Flash (cloud)",
        "local": "⭐ Local → DeepSeek V4 (local)",
        "embedding": "⭐ Embedding → Nomic Embed Text",
    }
    return names.get(name, name.replace('-', ' ').title())


def generate_settings(model_entries):
    """Generate the VS Code settings JSON using customendpoint format."""
    models_array = []

    for entry in model_entries:
        name = entry["name"]
        caps = _model_capabilities(name, "")
        friendly = _friendly_name(name)

        model_obj = {
            "id": name,
            "name": friendly,
            "url": "http://localhost:4000/v1/chat/completions",
            "toolCalling": caps["toolCalling"],
            "vision": caps["vision"],
            "maxInputTokens": caps["maxInputTokens"],
            "maxOutputTokens": caps["maxOutputTokens"],
        }
        models_array.append(model_obj)

    settings = {
        "github.copilot.chat.languageModels": [
            {
                "name": "LiteLLM-local",
                "vendor": "customendpoint",
                "apiKey": "${input:chat.lm.secret.-5ddf5cda}",
                "apiType": "chat-completions",
                "models": models_array,
            }
        ]
    }

    return settings


def write_settings(settings, output_path: Path):
    """Write settings to .vscode/settings.json."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(settings, indent=2) + "\n")
    models = settings["github.copilot.chat.languageModels"][0]["models"]
    print(f"✅ Generated {output_path}")
    print(f"   Models: {len(models)} total")


def main():
    model_entries = parse_config(CONFIG_PATH)
    if not model_entries:
        print("Error: no model entries found in config.yaml")
        sys.exit(1)

    settings = generate_settings(model_entries)
    write_settings(settings, VSCODE_SETTINGS_PATH)


if __name__ == "__main__":
    main()
