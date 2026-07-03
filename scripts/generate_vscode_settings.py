#!/usr/bin/env python3
"""Regenerate .vscode/settings.json from config.yaml.

Reads the model_list from config.yaml and generates VS Code Copilot Chat
language model entries so the two never drift out of sync.

Capabilities (tool calling, vision, input/output token limits) are derived
from each entry's own `litellm_params.model` and `model_info` block in
config.yaml -- not from the local model_name/alias string. This matters
because several entries (e.g. "best-chat", "fast", "embedding") are aliases
that point at the same underlying model as a "canonical" entry elsewhere in
the file. Guessing capabilities from the alias name instead of the real
underlying model caused three confirmed bugs before this rewrite:
  - "best-chat" (-> anthropic/claude-sonnet-4-6) reported vision: false and
    maxInputTokens: 128000 instead of the real vision: true / 200000.
  - "fast" (-> groq/llama-3.3-70b-versatile) reported maxOutputTokens: 16000
    instead of Groq's real ~8000 cap, risking a forced mid-response cutoff.
  - "embedding" (-> ollama/nomic-embed-text) reported toolCalling: true and
    maxOutputTokens: 16000 instead of false / 1, since it's an
    embedding-only model with no chat/tool-calling support.

maxOutputTokens is also capped conservatively (see SAFE_MAX_OUTPUT_TOKENS
below) because VS Code Copilot Chat has an internal response-size ceiling
(~60KB) and crashes with "Response too long" instead of truncating
gracefully when a completion is cut off by hitting its token limit
(finish_reason: "length"). See docs/TROUBLESHOOTING.md and
AGENT-ISSUES.md (H-6) for background.

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

# Conservative default output cap. VS Code Copilot Chat's internal buffer
# tops out well below what most providers advertise as their real max
# output; keeping this low reduces (though doesn't eliminate) the chance of
# tripping the "Response too long" crash. Embedding-mode models get 1
# (they don't generate text at all).
SAFE_MAX_OUTPUT_TOKENS = 8000
DEFAULT_MAX_INPUT_TOKENS = 128000

# Keyword match against the *underlying* litellm model id (not the local
# alias name) to guess vision support. Best-effort; correct as of the
# models configured when this list was written -- update if a new
# vision-capable provider/model is added and doesn't match any keyword.
VISION_KEYWORDS = [
    "vl-", "vision", "gemini", "kimi", "minimax", "mistral-large",
    "claude-sonnet", "claude-opus",
]

MODEL_NAME_RE = re.compile(
    r'^  - model_name:\s+(\S+)\s*\n((?:  (?!- model_name:).*\n?)*)',
    re.MULTILINE,
)
UNDERLYING_MODEL_RE = re.compile(r'^\s*model:\s*(\S+)\s*$', re.MULTILINE)
MODE_RE = re.compile(r'^\s*mode:\s*(\S+)\s*$', re.MULTILINE)
MAX_TOKENS_RE = re.compile(r'^\s*max_tokens:\s*(\d+)\s*$', re.MULTILINE)


def parse_config(config_path: Path):
    """Parse model_list entries from config.yaml.

    Returns a list of dicts: name, underlying_model, mode, max_tokens.
    """
    if not config_path.exists():
        print(f"Error: {config_path} not found")
        sys.exit(1)

    content = config_path.read_text()

    entries = []
    for match in MODEL_NAME_RE.finditer(content):
        name = match.group(1)
        block = match.group(2)

        model_match = UNDERLYING_MODEL_RE.search(block)
        mode_match = MODE_RE.search(block)
        max_tokens_match = MAX_TOKENS_RE.search(block)

        entries.append({
            "name": name,
            "underlying_model": model_match.group(1) if model_match else "",
            "mode": mode_match.group(1) if mode_match else "chat",
            "max_tokens": int(max_tokens_match.group(1)) if max_tokens_match else None,
        })

    return entries


def _model_capabilities(entry: dict) -> dict:
    """Determine model capabilities from the entry's real config data."""
    underlying = entry["underlying_model"].lower()
    mode = entry["mode"]

    if mode == "embedding":
        return {
            "toolCalling": False,
            "vision": False,
            "maxInputTokens": entry["max_tokens"] or 8192,
            "maxOutputTokens": 1,
        }

    # Ollama tags use ":" as a separator (e.g. "qwen3-vl:235b-cloud"); treat
    # it the same as "-" so keyword matches like "vl-" still fire.
    underlying_norm = underlying.replace(":", "-")
    vision = any(kw in underlying_norm for kw in VISION_KEYWORDS)

    return {
        "toolCalling": True,
        "vision": vision,
        "maxInputTokens": entry["max_tokens"] or DEFAULT_MAX_INPUT_TOKENS,
        "maxOutputTokens": SAFE_MAX_OUTPUT_TOKENS,
    }


def _friendly_name(name: str) -> str:
    """Map model IDs to friendly display names."""
    names = {
        "deepseek-v4-pro": "DeepSeek V4 Pro",
        "deepseek-v4-flash": "DeepSeek V4 Flash",
        "deepseek-r1": "DeepSeek R1",
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
        "glm-5.2-cloud": "GLM 5.2 (cloud)",
        "kimi-k2.5-cloud": "Kimi K2.5 (cloud)",
        "kimi-k2.6-cloud": "Kimi K2.6 (cloud)",
        "kimi-k2.7-code-cloud": "Kimi K2.7 Code (cloud)",
        "minimax-m2.7-cloud": "MiniMax M2.7 (cloud)",
        "minimax-m3-cloud": "MiniMax M3 (cloud)",
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


def generate_settings(entries):
    """Generate the VS Code settings JSON using customendpoint format."""
    models_array = []
    warnings = []

    for entry in entries:
        name = entry["name"]
        if not entry["underlying_model"]:
            warnings.append(
                f"  - {name}: no litellm_params.model found; "
                f"falling back to generic chat capabilities"
            )
        caps = _model_capabilities(entry)
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

    if warnings:
        print("Warnings:")
        print("\n".join(warnings))

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
    entries = parse_config(CONFIG_PATH)
    if not entries:
        print("Error: no model entries found in config.yaml")
        sys.exit(1)

    settings = generate_settings(entries)
    write_settings(settings, VSCODE_SETTINGS_PATH)


if __name__ == "__main__":
    main()
