# liteLLM-local

A local LiteLLM proxy that gives you a **single OpenAI-compatible endpoint** for all your AI providers — no markup, no middleman, direct provider pricing.

## Why

Running models through OpenRouter is convenient but expensive. With LiteLLM running locally, VS Code Copilot Chat (and any other tool) points to `http://localhost:4000` and your API keys go **direct to each provider** at their published rates.

Tested providers in this setup:
- [DeepSeek](https://platform.deepseek.com) — best for coding ($0.44/$0.87 per 1M tokens)
- [Anthropic](https://console.anthropic.com) — Claude models
- [Groq](https://console.groq.com) — fast inference
- [Mistral](https://console.mistral.ai) — strong European models, good price/quality
- [Moonshot / Kimi](https://platform.moonshot.cn)
- [Ollama](http://localhost:11434) — local models, free

---

## Prerequisites

- Python 3.9+
- [Ollama](https://ollama.com) installed and running (for local models)
- API keys for the providers you want to use

---

## Installation

```bash
pip install litellm[proxy]
```

---

## Configuration

Create a `config.yaml` in this repo:

```yaml
model_list:
  # DeepSeek — best for coding
  - model_name: deepseek-v4-pro
    litellm_params:
      model: deepseek/deepseek-chat
      api_key: os.environ/DEEPSEEK_API_KEY

  # Anthropic Claude
  - model_name: claude-sonnet
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: claude-opus
    litellm_params:
      model: anthropic/claude-opus-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

  # Groq — fast inference
  - model_name: groq-llama
    litellm_params:
      model: groq/llama-3.3-70b-versatile
      api_key: os.environ/GROQ_API_KEY

  # Ollama — local, free
  - model_name: qwen2.5-coder
    litellm_params:
      model: ollama/qwen2.5-coder:14b
      api_base: http://localhost:11434

litellm_settings:
  drop_params: true        # strips unsupported params (fixes DeepSeek reasoning_content issue)
  set_verbose: false
```

Create a `.env` file (never commit this):

```env
DEEPSEEK_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GROQ_API_KEY=gsk_...
```

---

## Running

```bash
# Load env vars and start the proxy
source .env && litellm --config config.yaml --port 4000
```

Or use the included start script:

```bash
./start.sh
```

The proxy will be available at `http://localhost:4000`.

---

## VS Code Copilot Chat Setup

Add to your VS Code `settings.json`:

```json
"github.copilot.chat.languageModels": [
  {
    "name": "LiteLLM Local",
    "vendor": "openai",
    "url": "http://localhost:4000/v1",
    "apiKey": "anything",
    "model": "deepseek-v4-pro"
  }
]
```

> The `apiKey` field can be any non-empty string — authentication is handled by LiteLLM using your provider keys.

Switch models by changing the `model` field to any name defined in `config.yaml`.

---

## Auto-start on Mac (optional)

To have LiteLLM start automatically on login, create a launchd plist:

```bash
cat > ~/Library/LaunchAgents/com.litellm.local.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.litellm.local</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>cd /path/to/liteLLM-local && source .env && litellm --config config.yaml --port 4000</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.litellm.local.plist
```

---

## Cost Comparison

| Provider | Model | Input /1M | Output /1M |
|---|---|---|---|
| DeepSeek (direct) | deepseek-chat (V4 Pro) | $0.44 | $0.87 |
| Anthropic (direct) | claude-sonnet-4-6 | $3.00 | $15.00 |
| Groq (direct) | llama-3.3-70b | ~$0.59 | ~$0.79 |
| Ollama local | qwen2.5-coder:14b | free | free |
| OpenRouter | (same models) | +10–15% markup | +10–15% markup |

---

## Files

```
liteLLM-local/
├── config.yaml       # model definitions
├── .env              # API keys (gitignored)
├── .gitignore
├── start.sh          # convenience start script
└── README.md
```

---

## .gitignore

Make sure `.env` is never committed:

```
.env
__pycache__/
*.pyc
```